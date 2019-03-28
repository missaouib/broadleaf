---
layout: post

title: spark-shell脚本分析

category: spark

tags: [spark]

description: 本文主要分析spark-shell脚本的运行逻辑，涉及到spark-submit、spark-class等脚本的分析，希望通过分析脚本以了解spark中各个进程的参数、JVM参数和内存大小如何设置。

published: true

---

本文主要分析spark-shell脚本的运行逻辑，涉及到spark-submit、spark-class等脚本的分析，希望通过分析脚本以了解spark中各个进程的参数、JVM参数和内存大小如何设置。

# spark-shell

使用yum安装spark之后，你可以直接在终端运行spark-shell命令，或者在spark的home目录/usr/lib/spark下运行bin/spark-shell命令，这样就可以进入到spark命令行交互模式。

**spark-shell 脚本是如何运行的呢**？该脚本代码如下：

~~~bash
#
# Shell script for starting the Spark Shell REPL

cygwin=false
case "`uname`" in
  CYGWIN*) cygwin=true;;
esac

# Enter posix mode for bash
set -o posix

## Global script variables
FWDIR="$(cd "`dirname "$0"`"/..; pwd)"

function usage() {
  echo "Usage: ./bin/spark-shell [options]"
  "$FWDIR"/bin/spark-submit --help 2>&1 | grep -v Usage 1>&2
  exit 0
}

if [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  usage
fi

source "$FWDIR"/bin/utils.sh
SUBMIT_USAGE_FUNCTION=usage
gatherSparkSubmitOpts "$@"

# SPARK-4161: scala does not assume use of the java classpath,
# so we need to add the "-Dscala.usejavacp=true" flag mnually. We
# do this specifically for the Spark shell because the scala REPL
# has its own class loader, and any additional classpath specified
# through spark.driver.extraClassPath is not automatically propagated.
SPARK_SUBMIT_OPTS="$SPARK_SUBMIT_OPTS -Dscala.usejavacp=true"

function main() {
  if $cygwin; then
    # Workaround for issue involving JLine and Cygwin
    # (see http://sourceforge.net/p/jline/bugs/40/).
    # If you're using the Mintty terminal emulator in Cygwin, may need to set the
    # "Backspace sends ^H" setting in "Keys" section of the Mintty options
    # (see https://github.com/sbt/sbt/issues/562).
    stty -icanon min 1 -echo > /dev/null 2>&1
    export SPARK_SUBMIT_OPTS="$SPARK_SUBMIT_OPTS -Djline.terminal=unix"
    "$FWDIR"/bin/spark-submit --class org.apache.spark.repl.Main "${SUBMISSION_OPTS[@]}" spark-shell "${APPLICATION_OPTS[@]}"
    stty icanon echo > /dev/null 2>&1
  else
    export SPARK_SUBMIT_OPTS
    "$FWDIR"/bin/spark-submit --class org.apache.spark.repl.Main "${SUBMISSION_OPTS[@]}" spark-shell "${APPLICATION_OPTS[@]}"
  fi
}

# Copy restore-TTY-on-exit functions from Scala script so spark-shell exits properly even in
# binary distribution of Spark where Scala is not installed
exit_status=127
saved_stty=""

# restore stty settings (echo in particular)
function restoreSttySettings() {
  stty $saved_stty
  saved_stty=""
}

function onExit() {
  if [[ "$saved_stty" != "" ]]; then
    restoreSttySettings
  fi
  exit $exit_status
}

# to reenable echo if we are interrupted before completing.
trap onExit INT

# save terminal settings
saved_stty=$(stty -g 2>/dev/null)
# clear on error so we don't later try to restore them
if [[ ! $? ]]; then
  saved_stty=""
fi

main "$@"

# record the exit status lest it be overwritten:
# then reenable echo and propagate the code.
exit_status=$?
onExit
~~~

从上往下一步步分析，首先是判断是否为cygwin，这里用到了bash中的`case`语法：

~~~bash
cygwin=false
case "`uname`" in
  CYGWIN*) cygwin=true;;
esac
~~~

>在linux系统中，`uname`命令的运行结果为linux，其值不等于`CYGWIN*`，故cygwin=false。

开启bash的posix模式：

~~~bash
set -o posix
~~~

获取上级目录绝对路径，这里使用到了`dirname`命令：

~~~bash
FWDIR="$(cd "`dirname "$0"`"/..; pwd)"
~~~

> 提示：bash 中，$0 是获取脚本名称

判断输入参数中是否有`--help`或者`-h`，如果有，则打印使用说明，实际上运行的是`/bin/spark-submit --help`命令：

~~~bash
function usage() {
  echo "Usage: ./bin/spark-shell [options]"
  "$FWDIR"/bin/spark-submit --help 2>&1 | grep -v Usage 1>&2
  exit 0
}

if [[ "$@" = *--help ]] || [[ "$@" = *-h ]]; then
  usage
fi
~~~

> 提示：
> 
> - 2>&1 的意思是将标准错误也输出到标准输出当中；1>&2是将标准输出输出到标准错误当中
> - bash 中，$@ 是获取脚本所有的输入参数

再往后面是定义了一个main方法，并将spark-shell的输入参数传给该方法运行，main方法中判断是否是cygwin模式，如果不是，则运行

~~~bash
SPARK_SUBMIT_OPTS="$SPARK_SUBMIT_OPTS -Dscala.usejavacp=true"


export SPARK_SUBMIT_OPTS
"$FWDIR"/bin/spark-submit --class org.apache.spark.repl.Main "${SUBMISSION_OPTS[@]}" spark-shell "${APPLICATION_OPTS[@]}"
~~~

> 提示："${SUBMISSION_OPTS[@]}" 这是什么意思？

从上面可以看到，其实最后调用的是spark-submit命令，并指定`--class`参数为`org.apache.spark.repl.Main`类，后面接的是spark-submit的提交参数，再后面是spark-shell，最后是传递应用的参数。

最后，是获取main方法运行结果：

~~~bash
exit_status=$?
onExit
~~~

> 提示： bash 中，`$?`是获取上个命令运行结束返回的状态码

如果以调试模式运行spark-shell，在不加参数的情况下，输出内容为：

~~~
+ cygwin=false
+ case "`uname`" in
++ uname
+ set -o posix
+++ dirname /usr/lib/spark/bin/spark-shell
++ cd /usr/lib/spark/bin/..
++ pwd
+ FWDIR=/usr/lib/spark
+ [[ '' = *--help ]]
+ [[ '' = *-h ]]
+ source /usr/lib/spark/bin/utils.sh
+ SUBMIT_USAGE_FUNCTION=usage
+ gatherSparkSubmitOpts
+ '[' -z usage ']'
+ SUBMISSION_OPTS=()
+ APPLICATION_OPTS=()
+ (( 0 ))
+ export SUBMISSION_OPTS
+ export APPLICATION_OPTS
+ SPARK_SUBMIT_OPTS=' -Dscala.usejavacp=true'
+ exit_status=127
+ saved_stty=
+ trap onExit INT
++ stty -g
+ saved_stty=500:5:bf:8a3b:3:1c:7f:15:4:0:1:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0
+ [[ ! -n 0 ]]
+ main
+ false
+ export SPARK_SUBMIT_OPTS
+ /usr/lib/spark/bin/spark-submit --class org.apache.spark.repl.Main spark-shell
~~~

>提示：通过运行`set -x`可以开启bash调试代码的特性。

接下来就涉及到spark-submit命令的逻辑了。

# spark-submit

完整的spark-submit脚本内容如下：

~~~bash
# NOTE: Any changes in this file must be reflected in SparkSubmitDriverBootstrapper.scala!

export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
ORIG_ARGS=("$@")

# Set COLUMNS for progress bar
export COLUMNS=`tput cols`

while (($#)); do
  if [ "$1" = "--deploy-mode" ]; then
    SPARK_SUBMIT_DEPLOY_MODE=$2
  elif [ "$1" = "--properties-file" ]; then
    SPARK_SUBMIT_PROPERTIES_FILE=$2
  elif [ "$1" = "--driver-memory" ]; then
    export SPARK_SUBMIT_DRIVER_MEMORY=$2
  elif [ "$1" = "--driver-library-path" ]; then
    export SPARK_SUBMIT_LIBRARY_PATH=$2
  elif [ "$1" = "--driver-class-path" ]; then
    export SPARK_SUBMIT_CLASSPATH=$2
  elif [ "$1" = "--driver-java-options" ]; then
    export SPARK_SUBMIT_OPTS=$2
  elif [ "$1" = "--master" ]; then
    export MASTER=$2
  fi
  shift
done

if [ -z "$SPARK_CONF_DIR" ]; then
  export SPARK_CONF_DIR="$SPARK_HOME/conf"
fi
DEFAULT_PROPERTIES_FILE="$SPARK_CONF_DIR/spark-defaults.conf"
if [ "$MASTER" == "yarn-cluster" ]; then
  SPARK_SUBMIT_DEPLOY_MODE=cluster
fi
export SPARK_SUBMIT_DEPLOY_MODE=${SPARK_SUBMIT_DEPLOY_MODE:-"client"}
export SPARK_SUBMIT_PROPERTIES_FILE=${SPARK_SUBMIT_PROPERTIES_FILE:-"$DEFAULT_PROPERTIES_FILE"}

# For client mode, the driver will be launched in the same JVM that launches
# SparkSubmit, so we may need to read the properties file for any extra class
# paths, library paths, java options and memory early on. Otherwise, it will
# be too late by the time the driver JVM has started.

if [[ "$SPARK_SUBMIT_DEPLOY_MODE" == "client" && -f "$SPARK_SUBMIT_PROPERTIES_FILE" ]]; then
  # Parse the properties file only if the special configs exist
  contains_special_configs=$(
    grep -e "spark.driver.extra*\|spark.driver.memory" "$SPARK_SUBMIT_PROPERTIES_FILE" | \
    grep -v "^[[:space:]]*#"
  )
  if [ -n "$contains_special_configs" ]; then
    export SPARK_SUBMIT_BOOTSTRAP_DRIVER=1
  fi
fi

exec "$SPARK_HOME"/bin/spark-class org.apache.spark.deploy.SparkSubmit "${ORIG_ARGS[@]}"
~~~

首先是设置`SPARK_HOME`，并保留原始输入参数：

~~~bash
export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
ORIG_ARGS=("$@")
~~~

接下来，使用while语句配合`shift`命令，依次判断输入参数。

>说明：shift是将输入参数位置向左移位

设置`SPARK_CONF_DIR`变量，并判断spark-submit部署模式。

如果`$SPARK_CONF_DIR/spark-defaults.conf`文件存在，则检查是否设置`spark.driver.extra`开头的和`spark.driver.memory`变量，如果设置了，则`SPARK_SUBMIT_BOOTSTRAP_DRIVER`设为1。

最后，执行的是spark-class命令，输入参数为`org.apache.spark.deploy.SparkSubmit`类名和原始参数。

# spark-class

该脚本首先还是判断是否是cygwin，并设置SPARK_HOME和SPARK_CONF_DIR变量。

运行bin/load-spark-env.sh，加载spark环境变量。

spark-class至少需要传递一个参数，如果没有，则会打印脚本使用说明`Usage: spark-class <class> [<args>]`。

如果设置了`SPARK_MEM`变量，则提示`SPARK_MEM`变量过时，应该使用`spark.executor.memory`或者`spark.driver.memory`变量。

设置默认内存`DEFAULT_MEM`为512M，如果`SPARK_MEM`变量存在，则使用`SPARK_MEM`的值。

使用case语句判断spark-class传入的第一个参数的值：

~~~bash
SPARK_DAEMON_JAVA_OPTS="$SPARK_DAEMON_JAVA_OPTS -Dspark.akka.logLifecycleEvents=true"

# Add java opts and memory settings for master, worker, history server, executors, and repl.
case "$1" in
  # Master, Worker, and HistoryServer use SPARK_DAEMON_JAVA_OPTS (and specific opts) + SPARK_DAEMON_MEMORY.
  'org.apache.spark.deploy.master.Master')
    OUR_JAVA_OPTS="$SPARK_DAEMON_JAVA_OPTS $SPARK_MASTER_OPTS"
    OUR_JAVA_MEM=${SPARK_DAEMON_MEMORY:-$DEFAULT_MEM}
    ;;
  'org.apache.spark.deploy.worker.Worker')
    OUR_JAVA_OPTS="$SPARK_DAEMON_JAVA_OPTS $SPARK_WORKER_OPTS"
    OUR_JAVA_MEM=${SPARK_DAEMON_MEMORY:-$DEFAULT_MEM}
    ;;
  'org.apache.spark.deploy.history.HistoryServer')
    OUR_JAVA_OPTS="$SPARK_DAEMON_JAVA_OPTS $SPARK_HISTORY_OPTS"
    OUR_JAVA_MEM=${SPARK_DAEMON_MEMORY:-$DEFAULT_MEM}
    ;;

  # Executors use SPARK_JAVA_OPTS + SPARK_EXECUTOR_MEMORY.
  'org.apache.spark.executor.CoarseGrainedExecutorBackend')
    OUR_JAVA_OPTS="$SPARK_JAVA_OPTS $SPARK_EXECUTOR_OPTS"
    OUR_JAVA_MEM=${SPARK_EXECUTOR_MEMORY:-$DEFAULT_MEM}
    ;;
  'org.apache.spark.executor.MesosExecutorBackend')
    OUR_JAVA_OPTS="$SPARK_JAVA_OPTS $SPARK_EXECUTOR_OPTS"
    OUR_JAVA_MEM=${SPARK_EXECUTOR_MEMORY:-$DEFAULT_MEM}
    export PYTHONPATH="$FWDIR/python:$PYTHONPATH"
    export PYTHONPATH="$FWDIR/python/lib/py4j-0.8.2.1-src.zip:$PYTHONPATH"
    ;;

  # Spark submit uses SPARK_JAVA_OPTS + SPARK_SUBMIT_OPTS +
  # SPARK_DRIVER_MEMORY + SPARK_SUBMIT_DRIVER_MEMORY.
  'org.apache.spark.deploy.SparkSubmit')
    OUR_JAVA_OPTS="$SPARK_JAVA_OPTS $SPARK_SUBMIT_OPTS"
    OUR_JAVA_MEM=${SPARK_DRIVER_MEMORY:-$DEFAULT_MEM}
    if [ -n "$SPARK_SUBMIT_LIBRARY_PATH" ]; then
      if [[ $OSTYPE == darwin* ]]; then
       export DYLD_LIBRARY_PATH="$SPARK_SUBMIT_LIBRARY_PATH:$DYLD_LIBRARY_PATH"
      else
       export LD_LIBRARY_PATH="$SPARK_SUBMIT_LIBRARY_PATH:$LD_LIBRARY_PATH"
      fi
    fi
    if [ -n "$SPARK_SUBMIT_DRIVER_MEMORY" ]; then
      OUR_JAVA_MEM="$SPARK_SUBMIT_DRIVER_MEMORY"
    fi
    ;;

  *)
    OUR_JAVA_OPTS="$SPARK_JAVA_OPTS"
    OUR_JAVA_MEM=${SPARK_DRIVER_MEMORY:-$DEFAULT_MEM}
    ;;
esac
~~~

可能存在以下几种情况：

- `org.apache.spark.deploy.master.Master`
- `org.apache.spark.deploy.worker.Worker`
- `org.apache.spark.deploy.history.HistoryServer`
- `org.apache.spark.executor.CoarseGrainedExecutorBackend`
- `org.apache.spark.executor.MesosExecutorBackend`
- `org.apache.spark.deploy.SparkSubmit`

并分别设置每种情况下的Java运行参数和使用内存大小，以表格形式表示如下：

|| OUR_JAVA_OPTS | OUR_JAVA_MEM |
|:---|:---|:----|
| Master | $SPARK_DAEMON_JAVA_OPTS $SPARK_MASTER_OPTS | ${SPARK_DAEMON_MEMORY:-$DEFAULT_MEM} |
| Worker | $SPARK_DAEMON_JAVA_OPTS $SPARK_WORKER_OPTS | ${SPARK_DAEMON_MEMORY:-$DEFAULT_MEM} |
| HistoryServer | $SPARK_DAEMON_JAVA_OPTS $SPARK_HISTORY_OPTS | ${SPARK_DAEMON_MEMORY:-$DEFAULT_MEM} |
| CoarseGrainedExecutorBackend | $SPARK_JAVA_OPTS $SPARK_EXECUTOR_OPTS | ${SPARK_EXECUTOR_MEMORY:-$DEFAULT_MEM} |
| MesosExecutorBackend | $SPARK_JAVA_OPTS $SPARK_EXECUTOR_OPTS | ${SPARK_EXECUTOR_MEMORY:-$DEFAULT_MEM} |
| SparkSubmit | $SPARK_JAVA_OPTS $SPARK_SUBMIT_OPTS | ${SPARK_DRIVER_MEMORY:-$DEFAULT_MEM} |

通过上表就可以知道每一个spark中每个进程如何设置JVM参数和内存大小。

接下来是查找JAVA_HOME并检查Java版本。

设置SPARK_TOOLS_JAR变量。

运行bin/compute-classpath.sh计算classpath。

判断`SPARK_SUBMIT_BOOTSTRAP_DRIVER`变量值，如果该值为1，则运行`org.apache.spark.deploy.SparkSubmitDriverBootstrapper`类，以替换原来的`org.apache.spark.deploy.SparkSubmit`的类，执行的脚本为`exec "$RUNNER" org.apache.spark.deploy.SparkSubmitDriverBootstrapper "$@"`；否则，运行java命令`exec "$RUNNER" -cp "$CLASSPATH" $JAVA_OPTS "$@"`。

从最后运行的脚本可以看到，spark-class脚本的作用主要是查找java命令、计算环境变量、设置`JAVA_OPTS`等，至于运行的是哪个java类的main方法，取决于`SPARK_SUBMIT_BOOTSTRAP_DRIVER`变量的值。

接下来，就是要分析`org.apache.spark.deploy.SparkSubmitDriverBootstrapper`和`org.apache.spark.deploy.SparkSubmit`类的运行逻辑以及两者之间的区别，这部分内容见下篇文章。






