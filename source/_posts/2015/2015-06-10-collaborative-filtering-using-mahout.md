---
layout: post

title: 使用Mahout实现协同过滤

category: mahout

tags: [mahout,recommendation]

description: 本文主要记录使用Mahout实现协同过滤过程中的一些笔记，主要是记录源码相关的，不包含原理性的说明。

published: true

---

Mahout算法框架自带的推荐器有下面这些：

- GenericUserBasedRecommender：基于用户的推荐器，用户数量少时速度快；
- GenericItemBasedRecommender：基于商品推荐器，商品数量少时速度快，尤其当外部提供了商品相似度数据后效率更好；
- SlopeOneRecommender：基于slope-one算法的推荐器，在线推荐或更新较快，需要事先大量预处理运算，物品数量少时较好；
- SVDRecommender：奇异值分解，推荐效果较好，但之前需要大量预处理运算；
- KnnRecommender：基于k近邻算法(KNN)，适合于物品数量较小时；
- TreeClusteringRecommender：基于聚类的推荐器，在线推荐较快，之前需要大量预处理运算，用户数量较少时效果好；

Mahout最常用的三个推荐器是上述的前三个，本文主要讨论前两种的使用。

# 接口相关介绍

基于用户或物品的推荐器主要包括以下几个接口：

- `DataModel` 是用户喜好信息的抽象接口，它的具体实现支持从任意类型的数据源抽取用户喜好信息。Taste 默认提供 JDBCDataModel 和 FileDataModel，分别支持从数据库和文件中读取用户的喜好信息。
- `UserSimilarity` 和 `ItemSimilarity`。UserSimilarity 用于定义两个用户间的相似度，它是基于协同过滤的推荐引擎的核心部分，可以用来计算用户的“邻居”，这里我们将与当前用户口味相似的用户称为他的邻居。ItemSimilarity 类似的，计算内容之间的相似度。
- `UserNeighborhood` 用于基于用户相似度的推荐方法中，推荐的内容是基于找到与当前用户喜好相似的邻居用户的方式产生的。UserNeighborhood 定义了确定邻居用户的方法，具体实现一般是基于 UserSimilarity 计算得到的。
- `Recommender` 是推荐引擎的抽象接口，Taste 中的核心组件。程序中，为它提供一个 DataModel，它可以计算出对不同用户的推荐内容。实际应用中，主要使用它的实现类 GenericUserBasedRecommender 或者 GenericItemBasedRecommender，分别实现基于用户相似度的推荐引擎或者基于内容的推荐引擎。
- `RecommenderEvaluator`：评分器。
- `RecommenderIRStatsEvaluator`：搜集推荐性能相关的指标，包括准确率、召回率等等。

目前，Mahout为DataModel提供了以下几种实现：

- org.apache.mahout.cf.taste.impl.model.GenericDataModel
- org.apache.mahout.cf.taste.impl.model.GenericBooleanPrefDataModel
- org.apache.mahout.cf.taste.impl.model.PlusAnonymousUserDataModel
- org.apache.mahout.cf.taste.impl.model.file.FileDataModel
- org.apache.mahout.cf.taste.impl.model.hbase.HBaseDataModel
- org.apache.mahout.cf.taste.impl.model.cassandra.CassandraDataModel
- org.apache.mahout.cf.taste.impl.model.mongodb.MongoDBDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.SQL92JDBCDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.PostgreSQLJDBCDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.GenericJDBCDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.SQL92BooleanPrefJDBCDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.MySQLBooleanPrefJDBCDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.PostgreBooleanPrefSQLJDBCDataModel
- org.apache.mahout.cf.taste.impl.model.jdbc.ReloadFromJDBCDataModel

从类名上就可以大概猜出来每个DataModel的用途，奇怪的是竟然没有HDFS的DataModel，有人实现了一个，请参考[MAHOUT-1579](https://issues.apache.org/jira/browse/MAHOUT-1579)。

`UserSimilarity` 和 `ItemSimilarity` 相似度实现有以下几种：

- `CityBlockSimilarity`：基于Manhattan距离相似度
- `EuclideanDistanceSimilarity`：基于欧几里德距离计算相似度
- `LogLikelihoodSimilarity`：基于对数似然比的相似度
- `PearsonCorrelationSimilarity`：基于皮尔逊相关系数计算相似度
- `SpearmanCorrelationSimilarity`：基于皮尔斯曼相关系数相似度
- `TanimotoCoefficientSimilarity`：基于谷本系数计算相似度
- `UncenteredCosineSimilarity`：计算 Cosine 相似度

以上相似度的说明，请参考[Mahout推荐引擎介绍](/2014/09/22/mahout-recommend-engine.html)。

UserNeighborhood 主要实现有两种：

- NearestNUserNeighborhood：对每个用户取固定数量N个最近邻居
- ThresholdUserNeighborhood：对每个用户基于一定的限制，取落在相似度限制以内的所有用户为邻居

Recommender分为以下几种实现：

- GenericUserBasedRecommender：基于用户的推荐引擎
- GenericBooleanPrefUserBasedRecommender：基于用户的无偏好值推荐引擎
- GenericItemBasedRecommender：基于物品的推荐引擎
- GenericBooleanPrefItemBasedRecommender：基于物品的无偏好值推荐引擎

RecommenderEvaluator有以下几种实现：

- `AverageAbsoluteDifferenceRecommenderEvaluator`：计算平均差值
- `RMSRecommenderEvaluator`：计算均方根差

RecommenderIRStatsEvaluator的实现类是GenericRecommenderIRStatsEvaluator。

# 单机运行

首先，需要在maven中加入对mahout的依赖：

~~~xml
<dependency>
    <groupId>org.apache.mahout</groupId>
    <artifactId>mahout-core</artifactId>
    <version>0.9</version>
</dependency>

<dependency>
    <groupId>org.apache.mahout</groupId>
    <artifactId>mahout-integration</artifactId>
    <version>0.9</version>
</dependency>

<dependency>
    <groupId>org.apache.mahout</groupId>
    <artifactId>mahout-math</artifactId>
    <version>0.9</version>
</dependency>

<dependency>
    <groupId>org.apache.mahout</groupId>
    <artifactId>mahout-examples</artifactId>
    <version>0.9</version>
</dependency>
~~~

基于用户的推荐，以FileDataModel为例：

~~~java
File modelFile modelFile = new File("intro.csv");

DataModel model = new FileDataModel(modelFile);

//用户相似度，使用基于皮尔逊相关系数计算相似度
UserSimilarity similarity = new PearsonCorrelationSimilarity(model);

//选择邻居用户，使用NearestNUserNeighborhood实现UserNeighborhood接口，选择邻近的4个用户
UserNeighborhood neighborhood = new NearestNUserNeighborhood(4, similarity, model);

Recommender recommender = new GenericUserBasedRecommender(model, neighborhood, similarity);

//给用户1推荐4个物品
List<RecommendedItem> recommendations = recommender.recommend(1, 4);

for (RecommendedItem recommendation : recommendations) {
    System.out.println(recommendation);
}
~~~

>注意：
>FileDataModel要求输入文件中的字段分隔符为逗号或者制表符，如果你想使用其他分隔符，你可以扩展一个FileDataModel的实现，例如，mahout中已经提供了一个解析MoiveLens的数据集（分隔符为`::`）的实现GroupLensDataModel。

GenericUserBasedRecommender是基于用户的简单推荐器实现类，推荐主要参照传入的DataModel和UserNeighborhood，总体是三个步骤：

- (1) 从UserNeighborhood获取当前用户Ui最相似的K个用户集合{U1, U2, …Uk}；
- (2) 从这K个用户集合排除Ui的偏好商品，剩下的Item集合为{Item0, Item1, …Itemm}；
- (3) 对Item集合里每个Itemj计算Ui可能偏好程度值pref(Ui, Itemj)，并把Item按此数值从高到低排序，前N个item推荐给用户Ui。

对相同用户重复获得推荐结果，我们可以改用CachingRecommender来包装GenericUserBasedRecommender对象，将推荐结果缓存起来：

~~~java
Recommender cachingRecommender = new CachingRecommender(recommender);
~~~

上面代码可以在main方法中直接运行，然后，我们可以获取推荐模型的评分：

~~~java
//使用平均绝对差值获得评分
RecommenderEvaluator evaluator = new AverageAbsoluteDifferenceRecommenderEvaluator();
// 用RecommenderBuilder构建推荐引擎
RecommenderBuilder recommenderBuilder = new RecommenderBuilder() {
    @Override
    public Recommender buildRecommender(DataModel model) throws TasteException {
        UserSimilarity similarity = new PearsonCorrelationSimilarity(model);
        UserNeighborhood neighborhood = new NearestNUserNeighborhood(4, similarity, model);
        return new GenericUserBasedRecommender(model, neighborhood, similarity);
    }
};
// Use 70% of the data to train; test using the other 30%.
double score = evaluator.evaluate(recommenderBuilder, null, model, 0.7, 1.0);
System.out.println(score);
~~~

接下来，可以获取推荐结果的查准率和召回率：

~~~java
RecommenderIRStatsEvaluator statsEvaluator = new GenericRecommenderIRStatsEvaluator();
// Build the same recommender for testing that we did last time:
RecommenderBuilder recommenderBuilder = new RecommenderBuilder() {
    @Override
    public Recommender buildRecommender(DataModel model) throws TasteException {
        UserSimilarity similarity = new PearsonCorrelationSimilarity(model);
        UserNeighborhood neighborhood = new NearestNUserNeighborhood(4, similarity, model);
        return new GenericUserBasedRecommender(model, neighborhood, similarity);
    }
};
// 计算推荐4个结果时的查准率和召回率
IRStatistics stats = statsEvaluator.evaluate(recommenderBuilder,null, model, null, 4,
        GenericRecommenderIRStatsEvaluator.CHOOSE_THRESHOLD,1.0);
System.out.println(stats.getPrecision());
System.out.println(stats.getRecall());
~~~

如果是基于物品的推荐，代码大体相似，只是没有了UserNeighborhood，然后将上面代码中的User换成Item即可，完整代码如下：

~~~java
File modelFile modelFile = new File("intro.csv");

DataModel model = new FileDataModel(new File(file));

// Build the same recommender for testing that we did last time:
RecommenderBuilder recommenderBuilder = new RecommenderBuilder() {
    @Override
    public Recommender buildRecommender(DataModel model) throws TasteException {
        ItemSimilarity similarity = new PearsonCorrelationSimilarity(model);
        return new GenericItemBasedRecommender(model, similarity);
    }
};

//获取推荐结果
List<RecommendedItem> recommendations = recommenderBuilder.buildRecommender(model).recommend(1, 4);

for (RecommendedItem recommendation : recommendations) {
    System.out.println(recommendation);
}

//计算评分
RecommenderEvaluator evaluator =
        new AverageAbsoluteDifferenceRecommenderEvaluator();
// Use 70% of the data to train; test using the other 30%.
double score = evaluator.evaluate(recommenderBuilder, null, model, 0.7, 1.0);
System.out.println(score);

//计算查全率和查准率
RecommenderIRStatsEvaluator statsEvaluator = new GenericRecommenderIRStatsEvaluator();

// Evaluate precision and recall "at 2":
IRStatistics stats = statsEvaluator.evaluate(recommenderBuilder,
        null, model, null, 4,
        GenericRecommenderIRStatsEvaluator.CHOOSE_THRESHOLD,
        1.0);
System.out.println(stats.getPrecision());
System.out.println(stats.getRecall());
~~~

# 在Spark中运行

在Spark中运行，需要将Mahout相关的jar添加到Spark的classpath中，修改/etc/conf-env.sh，添加下面两行代码：

~~~properties
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:/usr/lib/mahout/lib/*"
SPARK_DIST_CLASSPATH="$SPARK_DIST_CLASSPATH:/usr/lib/mahout/*"
~~~

然后，以本地模式在spark-shell中运行下面代码交互测试：

~~~scala
//注意：这里是本地目录
val model = new FileDataModel(new File("intro.csv"))

val evaluator = new RMSRecommenderEvaluator()
val recommenderBuilder = new RecommenderBuilder {
  override def buildRecommender(dataModel: DataModel): Recommender = {
    val similarity = new LogLikelihoodSimilarity(dataModel)
    new GenericItemBasedRecommender(dataModel, similarity)
  }
}

val score = evaluator.evaluate(recommenderBuilder, null, model, 0.95, 0.05)
println(s"Score=$score")

val recommender=recommenderBuilder.buildRecommender(model)
val users=trainingRatings.map(_.user).distinct().take(20)

import scala.collection.JavaConversions._

val result=users.par.map{user=>
  user+","+recommender.recommend(user,40).map(_.getItemID).mkString(",")
}
~~~

<https://github.com/sujitpal/mia-scala-examples>上面有一个评估基于物品或是用户的各种相似度下的评分的类，叫做 RecommenderEvaluator，供大家学习参考。


# 分布式运行

Mahout提供了`org.apache.mahout.cf.taste.hadoop.item.RecommenderJob`类以MapReduce的方式来实现基于物品的协同过滤，查看该类的使用说明：

~~~bash
$ hadoop jar /usr/lib/mahout/mahout-examples-0.9-cdh5.4.0-job.jar org.apache.mahout.cf.taste.hadoop.item.RecommenderJob
15/06/10 16:19:34 ERROR common.AbstractJob: Missing required option --similarityClassname
Missing required option --similarityClassname
Usage:
 [--input <input> --output <output> --numRecommendations <numRecommendations>
--usersFile <usersFile> --itemsFile <itemsFile> --filterFile <filterFile>
--booleanData <booleanData> --maxPrefsPerUser <maxPrefsPerUser>
--minPrefsPerUser <minPrefsPerUser> --maxSimilaritiesPerItem
<maxSimilaritiesPerItem> --maxPrefsInItemSimilarity <maxPrefsInItemSimilarity>
--similarityClassname <similarityClassname> --threshold <threshold>
--outputPathForSimilarityMatrix <outputPathForSimilarityMatrix> --randomSeed
<randomSeed> --sequencefileOutput --help --tempDir <tempDir> --startPhase
<startPhase> --endPhase <endPhase>]
--similarityClassname (-s) similarityClassname    Name of distributed
                                                  similarity measures class to
                                                  instantiate, alternatively
                                                  use one of the predefined
                                                  similarities
                                                  ([SIMILARITY_COOCCURRENCE,
                                                  SIMILARITY_LOGLIKELIHOOD,
                                                  SIMILARITY_TANIMOTO_COEFFICIEN
                                                  T, SIMILARITY_CITY_BLOCK,
                                                  SIMILARITY_COSINE,
                                                  SIMILARITY_PEARSON_CORRELATION
                                                  ,
                                                  SIMILARITY_EUCLIDEAN_DISTANCE]
                                                  )
~~~

可见，该类可以接收的命令行参数如下：

- `--input(path)`: 存储用户偏好数据的目录，该目录下可以包含一个或多个存储用户偏好数据的文本文件；
- `--output(path)`: 结算结果的输出目录
- `--numRecommendations (integer)`: 为每个用户推荐的item数量，默认为10
- `--usersFile (path)`: 指定一个包含了一个或多个存储userID的文件路径，仅为该路径下所有文件包含的userID做推荐计算 (该选项可选)
- `--itemsFile (path)`: 指定一个包含了一个或多个存储itemID的文件路径，仅为该路径下所有文件包含的itemID做推荐计算 (该选项可选)
- `--filterFile (path)`: 指定一个路径，该路径下的文件包含了`[userID,itemID]`值对，userID和itemID用逗号分隔。计算结果将不会为user推荐`[userID,itemID]`值对中包含的item (该选项可选)
- `--booleanData (boolean)`: 如果输入数据不包含偏好数值，则将该参数设置为true，默认为false
- `--maxPrefsPerUser (integer)`: 在最后计算推荐结果的阶段，针对每一个user使用的偏好数据的最大数量，默认为10
- `--minPrefsPerUser (integer)`: 在相似度计算中，忽略所有偏好数据量少于该值的用户，默认为1
- `--maxSimilaritiesPerItem (integer)`: 针对每个item的相似度最大值，默认为100
- `--maxPrefsPerUserInItemSimilarity (integer)`: 在item相似度计算阶段，针对每个用户考虑的偏好数据最大数量，默认为1000
- `--similarityClassname (classname)`: 向量相似度计算类
- `outputPathForSimilarityMatrix`：SimilarityMatrix输出目录
- `--randomSeed`：随机种子
--`sequencefileOutput`：序列文件输出路径
- `--tempDir (path)`: 存储临时文件的目录，默认为当前用户的home目录下的temp目录
- `--startPhase`
- `--endPhase`
- `--threshold (double)`: 忽略相似度低于该阀值的item对

一个例子如下，使用SIMILARITY_LOGLIKELIHOOD相似度推荐物品：

~~~bash
$ hadoop jar /usr/lib/mahout/mahout-examples-0.9-cdh5.4.0-job.jar org.apache.mahout.cf.taste.hadoop.item.RecommenderJob --input /tmp/mahout/part-00000 --output /tmp/mahout-out  -s SIMILARITY_LOGLIKELIHOOD
~~~

默认情况下，mahout使用的reduce数目为1，这样造成大数据处理时效率较低，可以通过参数mahout执行脚本中的`MAHOUT_OPTS`中的`-Dmapred.reduce.tasks`参数指定reduce数目。

上面命令运行完成之后，会在当前用户的hdfs主目录生成temp目录，该目录可由`--tempDir (path)`参数设置：

~~~bash
$ hadoop fs -ls temp
Found 10 items
-rw-r--r--   3 root hadoop          7 2015-06-10 14:42 temp/maxValues.bin
-rw-r--r--   3 root hadoop    5522717 2015-06-10 14:42 temp/norms.bin
drwxr-xr-x   - root hadoop          0 2015-06-10 14:41 temp/notUsed
-rw-r--r--   3 root hadoop          7 2015-06-10 14:42 temp/numNonZeroEntries.bin
-rw-r--r--   3 root hadoop    3452222 2015-06-10 14:41 temp/observationsPerColumn.bin
drwxr-xr-x   - root hadoop          0 2015-06-10 14:47 temp/pairwiseSimilarity
drwxr-xr-x   - root hadoop          0 2015-06-10 14:52 temp/partialMultiply
drwxr-xr-x   - root hadoop          0 2015-06-10 14:39 temp/preparePreferenceMatrix
drwxr-xr-x   - root hadoop          0 2015-06-10 14:50 temp/similarityMatrix
drwxr-xr-x   - root hadoop          0 2015-06-10 14:42 temp/weights
~~~

观察yarn的管理界面，该命令会生成9个任务，任务名称依次是：

- PreparePreferenceMatrixJob-ItemIDIndexMapper-Reducer
- PreparePreferenceMatrixJob-ToItemPrefsMapper-Reducer
- PreparePreferenceMatrixJob-ToItemVectorsMapper-Reducer
- RowSimilarityJob-CountObservationsMapper-Reducer
- RowSimilarityJob-VectorNormMapper-Reducer
- RowSimilarityJob-CooccurrencesMapper-Reducer
- RowSimilarityJob-UnsymmetrifyMapper-Reducer
- partialMultiply
- RecommenderJob-PartialMultiplyMapper-Reducer

从任务名称，大概可以知道每个任务在做什么，如果你的输入参数不一样，生成的任务数可能不一样，这个需要测试一下才能确认。

在hdfs上查看输出的结果，用户和推荐结果用`\t`分隔，推荐结果中物品之间用逗号分隔，物品后面通过冒号连接评分：

~~~
843 [10709679:4.8334665,8389878:4.833426,9133835:4.7503786,10366169:4.7503185,9007487:4.750272,8149253:4.7501993,10366165:4.750115,9780049:4.750108,8581254:4.750071,10456307:4.7500467]
6253    [10117445:3.0375953,10340299:3.0340924,8321090:3.0340924,10086615:3.032164,10436801:3.0187714,9668385:3.0141575,8502110:3.013954,10476325:3.0074399,10318667:3.0004222,8320987:3.0003839]
~~~

使用Java API方式执行，请参考[Mahout分步式程序开发 基于物品的协同过滤ItemCF](http://blog.fens.me/hadoop-mahout-mapreduce-itemcf/)。

在Scala或者Spark中，可以以Java API或者命令方式运行，最后还可以通过Spark来处理推荐的结果，例如：过滤、去重、补足数据，这部分内容不做介绍。

# 参考文章

- [协同过滤原理与Mahout实现](http://matrix-lisp.github.io/blog/images/12/20/mahout-taste-CF/)
