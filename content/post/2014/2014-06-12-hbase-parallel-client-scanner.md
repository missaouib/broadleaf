---
layout: post

title: HBase客户端实现并行扫描
date: 2014-06-12T08:00:00+08:00

description: HBase中有一个类可以实现客户端扫描数据，叫做ClientScanner，该类不是并行的，有没有办法实现一个并行的扫描类，加快扫描速度呢？

keywords: HBase客户端实现并行扫描

categories: [ hbase ]

tags: [hbase]

published: true

---

HBase中有一个类可以实现客户端扫描数据，叫做ClientScanner，该类不是并行的，有没有办法实现一个并行的扫描类，加快扫描速度呢？

如果是一个Scan，我们可以根据startkey和stopkey将其拆分为多个子Scan，然后让这些Scan并行的去查询数据，然后分别返回执行结果。

# 实现方式

说明：我使用的HBase版本为：cdh4-0.94.15_4.7.0。

在org.apache.hadoop.hbase.client创建ParallelClientScanner类，代码如下：

~~~java
package org.apache.hadoop.hbase.client;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HConstants;
import org.apache.hadoop.hbase.Stoppable;
import org.apache.hadoop.hbase.util.Bytes;

public class ParallelClientScanner extends AbstractClientScanner {
  private static final int SCANNER_WAIT_TIME = 1000;
  private final HTableInterface table;
  private final int resultQueueSize;
  private final int threadCount;
  private List<Scan> scans;
  private Iterator<Scan> iter;
  private ParallelScannerWorkerThread currThread;
  private Queue<ParallelScannerWorkerThread> nextThreads;
  private boolean closed;

  public ParallelClientScanner(Configuration conf, Scan scan,
      byte[] tableName, List<byte[]> splitKeys) throws IOException {
    this(new HTable(conf, tableName), scan, splitKeys);
  }

  public ParallelClientScanner(HTableInterface table, Scan scan,
      List<byte[]> splitKeys) throws IOException {
    this.table = table;
    this.resultQueueSize = table.getConfiguration().getInt(
      "hbase.parallel.scanner.queue.size", 1000);

    this.threadCount = (table.getConfiguration().getInt(
      "hbase.parallel.scanner.thread.count", 10) - 1);

    this.scans = new ArrayList<Scan>();
    byte[] stopRow = scan.getStopRow();
    byte[] lastSplitKey = scan.getStartRow();
    Scan subScan = null;
    for (Iterator<byte[]> it = splitKeys.iterator(); it.hasNext();) {
      byte[] splitKey = (byte[]) it.next();
      if ((Bytes.compareTo(splitKey, lastSplitKey) <= 0)
          || ((Bytes.compareTo(splitKey, stopRow) >= 0) && (!Bytes
              .equals(stopRow, HConstants.EMPTY_END_ROW)))
          || (Bytes.equals(splitKey, HConstants.EMPTY_END_ROW))) {
        continue;
      }

      subScan = new Scan(scan);
      subScan.setStartRow(lastSplitKey);
      subScan.setStopRow(splitKey);
      subScan.setParallel(false);
      this.scans.add(subScan);
      lastSplitKey = splitKey;
    }
    subScan = new Scan(scan);
    subScan.setStartRow(lastSplitKey);
    subScan.setParallel(false);
    this.scans.add(subScan);

    this.nextThreads = new LinkedList<ParallelScannerWorkerThread>();
    this.closed = true;
    initialize();
  }

  public ParallelClientScanner(Configuration conf, List<Scan> scans,
      byte[] tableName) throws IOException {
    this(new HTable(conf, tableName), scans);
  }

  public ParallelClientScanner(HTableInterface table, List<Scan> scanList)
      throws IOException {
    if (null == scanList) {
      throw new IOException("ScanList cannot be null");
    }
    sort(scanList);

    this.table = table;
    this.resultQueueSize = table.getConfiguration().getInt(
      "hbase.parallel.scanner.queue.size", 1000);

    this.threadCount = (table.getConfiguration().getInt(
      "hbase.parallel.scanner.thread.count", 10) - 1);

    this.scans = new ArrayList<Scan>();
    Scan subScan = null;
    for (int i = 0; i < scanList.size(); i++) {
      subScan = new Scan((Scan) scanList.get(i));
      subScan.setParallel(false);
      this.scans.add(subScan);
    }

    this.nextThreads = new LinkedList<ParallelScannerWorkerThread>();
    this.closed = true;
    initialize();
  }

  protected void initialize() throws IOException {
    try {
      this.iter = this.scans.iterator();
      if (this.iter.hasNext()) {
        this.currThread = new ParallelScannerWorkerThread(
            (Scan) this.iter.next());
        this.currThread.start();
      }
      while ((this.iter.hasNext())
          && (this.nextThreads.size() < this.threadCount)) {
        ParallelScannerWorkerThread worker = new ParallelScannerWorkerThread(
            (Scan) this.iter.next());

        this.nextThreads.offer(worker);
        worker.start();
      }
      this.closed = false;
    } catch (IOException e) {
      close();
      throw e;
    }
  }

  public void close() {
    this.closed = true;
    if (this.currThread != null) {
      this.currThread.stop("Closed by user.");
    }
    for (ParallelScannerWorkerThread worker : this.nextThreads)
      worker.stop("Closed by user.");
  }

  public Result next() throws IOException {
    try {
      return nextInternal();
    } catch (IOException e) {
      close();
      throw e;
    }
  }

  private Result nextInternal() throws IOException {
    if ((this.closed) || (this.currThread == null)) {
      return null;
    }

    Result next = this.currThread.next();
    if (next != null) {
      return next;
    }

    if (this.currThread.isError()) {
      Exception ex = this.currThread.getException();
      throw ((ex instanceof IOException) ? (IOException) ex
          : new IOException(ex));
    }

    while ((next == null) && (this.currThread != null)) {
      if (!this.currThread.isStopped()) {
        this.currThread.stop("Scanner complete.");
      }
      this.currThread = ((ParallelScannerWorkerThread) this.nextThreads
          .poll());
      if (this.iter.hasNext()) {
        ParallelScannerWorkerThread worker = new ParallelScannerWorkerThread(
            (Scan) this.iter.next());

        this.nextThreads.offer(worker);
        worker.start();
      }
      if (this.currThread != null) {
        next = this.currThread.next();
      }
    }

    return next;
  }

  public Result[] next(int nbRows) throws IOException {
    ArrayList<Result> resultSets = new ArrayList<Result>(nbRows);
    for (int i = 0; i < nbRows; i++) {
      Result next = next();
      if (next == null) break;
      resultSets.add(next);
    }

    return (Result[]) resultSets.toArray(new Result[resultSets.size()]);
  }

  private void sort(List<Scan> scanList) throws IOException {
    Collections.sort(scanList, new ScanComparator());
    for (int i = 1; i < scanList.size(); i++) {
      byte[] currentStartRow = ((Scan) scanList.get(i)).getStartRow();
      byte[] lastStopRow = ((Scan) scanList.get(i - 1)).getStopRow();

      if ((lastStopRow == null) || (lastStopRow.length == 0)) throw new IOException(
          "Scan has overlap, last scan's stopRow is null");
      if ((currentStartRow == null) || (currentStartRow.length == 0)) {
        throw new IOException(
            "Scan has overlap, current scan's startRow is null");
      }
      if (0 >= Bytes.compareTo(lastStopRow, 0, lastStopRow.length,
        currentStartRow, 0, currentStartRow.length)) continue;
      throw new IOException(
          "Scan has overlap, current scan's startRow is smaller than last scan's stop row");
    }
  }

  private static class ScanComparator implements Comparator<Scan> {
    public int compare(Scan o1, Scan o2) {
      if ((o1.getStartRow() == null) || (o1.getStartRow().length == 0)) return -1;
      if ((o2.getStartRow() == null) || (o2.getStartRow().length == 0)) {
        return 1;
      }
      byte[] o1StartRow = o1.getStartRow();
      byte[] o2StartRow = o2.getStartRow();
      return Bytes.compareTo(o1StartRow, 0, o1StartRow.length,
        o2StartRow, 0, o2StartRow.length);
    }
  }

  private class ParallelScannerWorkerThread extends Thread implements
      Stoppable {
    private ResultScanner scanner;
    private BlockingQueue<Result> results;
    private Object empty;
    private AtomicBoolean stopped;
    private Exception exception;

    protected ParallelScannerWorkerThread(Scan scan) throws IOException {
      this.scanner = ParallelClientScanner.this.table.getScanner(scan);
      this.results = new ArrayBlockingQueue<Result>(
          ParallelClientScanner.this.resultQueueSize);
      this.empty = new Object();
      this.stopped = new AtomicBoolean(false);
    }

    public Result next() throws IOException {
      Result r = (Result) this.results.poll();
      while ((!this.stopped.get()) && (r == null)) {
        try {
          synchronized (this.empty) {
            this.empty.wait();
          }
          r = (Result) this.results.poll();
        } catch (InterruptedException e) {
          throw ((IOException) (IOException) new IOException()
              .initCause(e));
        }
      }

      return r;
    }

    public void stop(String why) {
      this.stopped.compareAndSet(false, true);
    }

    public boolean isStopped() {
      return this.stopped.get();
    }

    public boolean isError() {
      return this.exception != null;
    }

    public Exception getException() {
      return this.exception;
    }

    public void run() {
      try {
        Result r = this.scanner.next();
        while (r != null) {
          boolean added = false;
          while (!added) {
            added = this.results.offer(r, SCANNER_WAIT_TIME,
              TimeUnit.MILLISECONDS);
          }
          synchronized (this.empty) {
            this.empty.notify();
          }
          r = this.scanner.next();
        }
      } catch (IOException ioe) {
        this.exception = ioe;
      } catch (InterruptedException ite) {
        this.exception = ite;
      } finally {
        this.scanner.close();
        this.stopped.compareAndSet(false, true);
        synchronized (this.empty) {
          this.empty.notify();
        }
      }
    }
  }
}
~~~

然后，需要对Scan做些修改：

- 作为一个新特性，你需要修改SCAN_VERSION值
- 增加parallel属性，用于判断是否需要并行扫描
- 你需要修改序列化和反序列化方法，加上parallel的值
- 修改HTable中原来的`public ResultScanner getScanner(final Scan scan)`方法

修改SCAN_VERSION版本值为3，原来值为2：

~~~java
private static final byte SCAN_VERSION = (byte)3;
~~~

在合适地方添加一个parallel属性和get/set方法：

~~~java
this.parallel = scan.isParallel();

private boolean isParallel() {
	return parallel;
}

public void setParallel(boolean parallel) {
	this.parallel = parallel;
}
~~~

在public Scan(Scan scan)构造方法中初始化parallel属性：

~~~java
public Scan(Scan scan) throws IOException {
    startRow = scan.getStartRow();
    stopRow  = scan.getStopRow();
    maxVersions = scan.getMaxVersions();
    batch = scan.getBatch();
    caching = scan.getCaching();
    cacheBlocks = scan.getCacheBlocks();
    filter = scan.getFilter(); // clone?
    this.parallel = scan.isParallel(); 		// 初始化parallel属性
    TimeRange ctr = scan.getTimeRange();
    tr = new TimeRange(ctr.getMin(), ctr.getMax());
    Map<byte[], NavigableSet<byte[]>> fams = scan.getFamilyMap();
    for (Map.Entry<byte[],NavigableSet<byte[]>> entry : fams.entrySet()) {
      byte [] fam = entry.getKey();
      NavigableSet<byte[]> cols = entry.getValue();
      if (cols != null && cols.size() > 0) {
        for (byte[] col : cols) {
          addColumn(fam, col);
        }
      } else {
        addFamily(fam);
      }
    }
    for (Map.Entry<String, byte[]> attr : scan.getAttributesMap().entrySet()) {
      setAttribute(attr.getKey(), attr.getValue());
    }
  }

~~~

在`public Map<String, Object> toMap(int maxCols)`中添加上parallel属性：

~~~java
map.put("parallel", Boolean.valueOf(this.parallel));
~~~

修改readFields方法，在最后添加代码：

~~~java
if (version > 2) {
    this.parallel = in.readBoolean();
}
~~~

修改write方法，在最后添加代码：

~~~java
out.writeBoolean(this.parallel);
~~~

修改HTable中原来的`public ResultScanner getScanner(final Scan scan)`方法如下：

~~~java
public ResultScanner getScanner(final Scan scan) throws IOException {
	if (scan.getCaching() <= 0) {
		scan.setCaching(getScannerCaching());
	}
	return scan.getParallel() ? new ParallelClientScanner(this, scan, getStartKeysInRange(scan.getStartRow(), scan.getStopRow())) : new ClientScanner(getConfiguration(), scan, getTableName(), this.connection);
}
~~~

最后，如果你想再HBase shell中使用该特性，你要做如下修改：

修改src/main/ruby/hbase.rb，在`SELECT = "SELECT"`下面添加代码一行代码：

~~~ruby
COLUMN_INTERPRETER="COLUMN_INTERPRETER"
KEY = "KEY"
SELECT = "SELECT"
PARALLEL = "PARALLEL" 
~~~

修改src/main/ruby/hbase/table.rb，在`raw = args["RAW"] || false`下面添加一行代码：

~~~ruby
parallel = args["PARALLEL"] || false
~~~

在scan.setRaw(raw)下面添加一行代码：

~~~ruby
scan.setMaxVersions(versions) if versions > 1
scan.setTimeRange(timerange[0], timerange[1]) if timerange
scan.setRaw(raw)
scan.setParallel(parallel)
~~~

修改完之后，编译源代码，就可以进行测试了。

# 测试

1. 通过hbase shell测试

运行hbase shell进行测试：

~~~sql
hbase(main):003:0> scan 't',{PARALLEL=>true}
ROW                                      COLUMN+CELL                                                                                                        
 1                                       column=f:id, timestamp=1382528597662, value=1
 2                                       column=f:id, timestamp=1382528594343, value=2
 3                                       column=f:id, timestamp=1382528478893, value=3
 4                                       column=f:id, timestamp=1382528483161, value=4
4 row(s) in 0.0240 seconds
~~~

1. 通过hbase client测试

创建ParallelScannerTest.java类并添加如下代码：

~~~java
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.client.HTable;
import org.apache.hadoop.hbase.client.Result;
import org.apache.hadoop.hbase.client.ResultScanner;
import org.apache.hadoop.hbase.client.Scan;
import org.apache.hadoop.hbase.filter.CompareFilter.CompareOp;
import org.apache.hadoop.hbase.filter.SingleColumnValueFilter;
import org.apache.hadoop.hbase.util.Bytes;

public class ParallelScannerTest {
  public static void main(String[] args) throws Exception {
    Configuration conf = HBaseConfiguration.create();
    HTable table = new HTable(conf, "t");
    String startKey = "1";
    String stopKey = "3";
    Scan scan = new Scan(Bytes.toBytes(startKey), Bytes.toBytes(stopKey));
    int count = 0;
    
    scan.setParallel(true);

    ResultScanner scanner = table.getScanner(scan);
    Result r = scanner.next();
    while (r != null) {
      count++;
      r = scanner.next();
    }
    System.out.println("++ Scanning finished with count : " + count + " ++");
    scanner.close();
    table.close();
  }
}
~~~

运行该类并查看输出结果。

你可以在hbase-site.xml中修改线程数大小和队列大小，下面两个参数：

- hbase.parallel.scanner.queue.size
- hbase.parallel.scanner.thread.count

以上源代码及所做的修改我已提交到我github仓库上hbase的cdh4-0.94.15_4.7.0分支，见提交日志[add ParallelClientScanner](https://github.com/javachen/hbase/commit/66268c4179f674a7d64f36c91dd4070f1195d169)。
