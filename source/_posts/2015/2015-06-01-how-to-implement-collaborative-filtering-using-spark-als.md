---
layout: post

title: 如何使用Spark ALS实现协同过滤

category: spark

tags: [spark,mlib,recommendation,als]

description: 本文主要记录最近一段时间学习和实现Spark MLlib中的协同过滤的一些总结，希望对大家熟悉Spark ALS算法有所帮助。

published: true

---

本文主要记录最近一段时间学习和实现[Spark MLlib中的协同过滤](/2015/04/17-mllib-collaborative-filtering)的一些总结，希望对大家熟悉Spark ALS算法有所帮助。

>更新：
>
>1. 【2016.06.12】Spark1.4.0中MatrixFactorizationModel提供了recommendForAll方法实现离线批量推荐，见[SPARK-3066](https://issues.apache.org/jira/browse/SPARK-3066)。

# 测试环境

为了测试简单，在本地以local方式运行Spark，你需要做的是下载编译好的压缩包解压即可，可以参考[Spark本地模式运行](/2015/03/30-test-in-local-mode)。

测试数据使用[MovieLens](http://grouplens.org/datasets/movielens/)的[MovieLens 10M数据集](http://files.grouplens.org/datasets/movielens/ml-10m.zip)，下载之后解压到data目录。数据的格式请参考README中的说明，需要注意的是ratings.dat中的数据被处理过，`每个用户至少访问了20个商品`。

下面的代码均在spark-shell中运行，启动时候可以根据你的机器内存设置JVM参数，例如：

~~~bash
bin-shell --executor-memory 3g --driver-memory 3g --driver-java-options '-Xms2g -Xmx2g -XX:+UseCompressedOops'
~~~

# 预测评分

这个例子主要演示如何训练数据、评分并计算根均方差。

## 准备工作

首先，启动spark-shell，然后引入mllib包，我们需要用到ALS算法类和Rating评分类：

~~~scala
import org.apache.spark.mllib.recommendation.{ALS, Rating}
~~~

Spark的日志级别默认为INFO，你可以手动设置为WARN级别，同样先引入log4j依赖：

~~~scala
import org.apache.log4j.{Logger,Level}
~~~

然后，运行下面代码：

~~~scala
Logger.getLogger("org.apache.spark").setLevel(Level.WARN)
Logger.getLogger("org.eclipse.jetty.server").setLevel(Level.OFF)
~~~

## 加载数据

spark-shell启动成功之后，sc为内置变量，你可以通过它来加载测试数据：

~~~scala
val data = sc.textFile("data/ml-1m/ratings.dat")
~~~

接下来解析文件内容，获得用户对商品的评分记录：

~~~scala
val ratings = data.map(_.split("::") match { case Array(user, item, rate, ts) =>
  Rating(user.toInt, item.toInt, rate.toDouble)
}).cache()
~~~

查看第一条记录：

~~~scala
scala> ratings.first
res81: org.apache.spark.mllib.recommendation.Rating = Rating(1,1193,5.0)
~~~

我们可以统计文件中用户和商品数量：

~~~scala
val users = ratings.map(_.user).distinct()
val products = ratings.map(_.product).distinct()
println("Got "+ratings.count()+" ratings from "+users.count+" users on "+products.count+" products.")
~~~

可以看到如下输出：

~~~scala
//Got 1000209 ratings from 6040 users on 3706 products.
~~~

你可以对评分数据生成训练集和测试集，例如：训练集和测试集比例为8比2：

~~~scala
val splits = ratings.randomSplit(Array(0.8, 0.2), seed = 111l)
val training = splits(0).repartition(numPartitions)
val test = splits(1).repartition(numPartitions)
~~~

这里，我们是将评分数据全部当做训练集，并且也为测试集。

## 训练模型

接下来调用`ALS.train()`方法，进行模型训练：

~~~scala
val rank = 12
val lambda = 0.01
val numIterations = 20
val model = ALS.train(ratings, rank, numIterations, lambda)
~~~

训练完后，我们看看model中的用户和商品特征向量：

~~~scala
model.userFeatures
//res82: org.apache.spark.rdd.RDD[(Int, Array[Double])] = users MapPartitionsRDD[400] at mapValues at ALS.scala:218

model.userFeatures.count
//res84: Long = 6040

model.productFeatures
//res85: org.apache.spark.rdd.RDD[(Int, Array[Double])] = products MapPartitionsRDD[401] at mapValues at ALS.scala:222

model.productFeatures.count
//res86: Long = 3706
~~~

## 评测

我们要对比一下预测的结果，注意：**我们将训练集当作测试集**来进行对比测试。从训练集中获取用户和商品的映射：

~~~scala
val usersProducts= ratings.map { case Rating(user, product, rate) =>
  (user, product)
}
~~~

显然，测试集的记录数等于评分总记录数，验证一下：

~~~scala
usersProducts.count  //Long = 1000209
~~~

使用推荐模型对用户商品进行预测评分，得到预测评分的数据集：

~~~scala
var predictions = model.predict(usersProducts).map { case Rating(user, product, rate) =>
    ((user, product), rate)
}
~~~

查看其记录数：

~~~scala
predictions.count //Long = 1000209
~~~

将真实评分数据集与预测评分数据集进行合并，这样得到用户对每一个商品的实际评分和预测评分：

~~~scala
val ratesAndPreds = ratings.map { case Rating(user, product, rate) =>
  ((user, product), rate)
}.join(predictions)

ratesAndPreds.count  //Long = 1000209
~~~

然后计算根均方差：

~~~scala
val rmse= math.sqrt(ratesAndPreds.map { case ((user, product), (r1, r2)) =>
  val err = (r1 - r2)
  err * err
}.mean())

println(s"RMSE = $rmse")
~~~

上面这段代码其实就是`对测试集进行评分预测并计算相似度`，这段代码可以抽象为一个方法，如下：

~~~scala
/** Compute RMSE (Root Mean Squared Error). */
def computeRmse(model: MatrixFactorizationModel, data: RDD[Rating]) = {
  val usersProducts = data.map { case Rating(user, product, rate) =>
    (user, product)
  }

  val predictions = model.predict(usersProducts).map { case Rating(user, product, rate) =>
    ((user, product), rate)
  }

  val ratesAndPreds = data.map { case Rating(user, product, rate) =>
    ((user, product), rate)
  }.join(predictions)

  math.sqrt(ratesAndPreds.map { case ((user, product), (r1, r2)) =>
    val err = (r1 - r2)
    err * err
  }.mean())
}
~~~

除了RMSE指标，我们还可以及时AUC以及Mean average precision at K (MAPK)，关于AUC的计算方法，参考[RunRecommender.scala](https://github.com/sryza/aas/blob/master/ch03-recommender/src/main/scala/com/cloudera/datascience/recommender/RunRecommender.scala)，关于MAPK的计算方法可以参考《[Packt.Machine Learning with Spark.2015.pdf](http://f.dataguru.cn/thread-495493-1-1.html)》一书第四章节内容，或者你可以看本文后面内容。

## 保存真实评分和预测评分

我们还可以保存用户对商品的真实评分和预测评分记录到本地文件：

~~~scala
ratesAndPreds.sortByKey().repartition(1).sortBy(_._1).map({
  case ((user, product), (rate, pred)) => (user + "," + product + "," + rate + "," + pred)
}).saveAsTextFile("/tmp/result")
~~~

上面这段代码先按用户排序，然后重新分区确保目标目录中只生成一个文件。如果你重复运行这段代码，则需要先删除目标路径：

~~~scala
import scala.sys.process._
"rm -r /tmp/result".!
~~~

我们还可以对预测的评分结果按用户进行分组并按评分倒排序：

~~~scala
predictions.map { case ((user, product), rate) =>
  (user, (product, rate))
}.groupByKey(numPartitions).map{case (user_id,list)=>
  (user_id,list.toList.sortBy {case (goods_id,rate)=> - rate})
}
~~~

# 给一个用户推荐商品

这个例子主要是记录如何给一个或大量用户进行推荐商品，例如，对用户编号为384的用户进行推荐，查出该用户在测试集中评分过的商品。

找出5个用户：

~~~scala
users.take(5) 
//Array[Int] = Array(384, 1084, 4904, 3702, 5618)
~~~

查看用户编号为384的用户的预测结果中预测评分排前10的商品：

~~~scala
val userId = users.take(1)(0) //384
val K = 10
val topKRecs = model.recommendProducts(userId, K)
println(topKRecs.mkString("\n"))
//    Rating(384,2545,8.354966018818265)
//    Rating(384,129,8.113083736094676)
//    Rating(384,184,8.038113395650853)
//    Rating(384,811,7.983433591425284)
//    Rating(384,1421,7.912044967873945)
//    Rating(384,1313,7.719639594879865)
//    Rating(384,2892,7.53667094600392)
//    Rating(384,2483,7.295378004543803)
//    Rating(384,397,7.141158013610967)
//    Rating(384,97,7.071089782695754)
~~~

查看该用户的评分记录：

~~~scala
val goodsForUser=ratings.keyBy(_.user).lookup(384)
// Seq[org.apache.spark.mllib.recommendation.Rating] = WrappedArray(Rating(384,2055,2.0), Rating(384,1197,4.0), Rating(384,593,5.0), Rating(384,599,3.0), Rating(384,673,2.0), Rating(384,3037,4.0), Rating(384,1381,2.0), Rating(384,1610,4.0), Rating(384,3074,4.0), Rating(384,204,4.0), Rating(384,3508,3.0), Rating(384,1007,3.0), Rating(384,260,4.0), Rating(384,3487,3.0), Rating(384,3494,3.0), Rating(384,1201,5.0), Rating(384,3671,5.0), Rating(384,1207,4.0), Rating(384,2947,4.0), Rating(384,2951,4.0), Rating(384,2896,2.0), Rating(384,1304,5.0))

productsForUser.size //Int = 22
productsForUser.sortBy(-_.rating).take(10).map(rating => (rating.product, rating.rating)).foreach(println)
//    (593,5.0)
//    (1201,5.0)
//    (3671,5.0)
//    (1304,5.0)
//    (1197,4.0)
//    (3037,4.0)
//    (1610,4.0)
//    (3074,4.0)
//    (204,4.0)
//    (260,4.0)
~~~

可以看到该用户对22个商品评过分以及浏览的商品是哪些。

我们可以该用户对某一个商品的实际评分和预测评分方差为多少：

~~~scala
val actualRating = productsForUser.take(1)(0)
//actualRating: org.apache.spark.mllib.recommendation.Rating = Rating(384,2055,2.0)    val predictedRating = model.predict(789, actualRating.product)
val predictedRating = model.predict(384, actualRating.product)
//predictedRating: Double = 1.9426030777174637
val squaredError = math.pow(predictedRating - actualRating.rating, 2.0)
//squaredError: Double = 0.0032944066875075172
~~~

如何找出和一个已知商品最相似的商品呢？这里，我们可以使用余弦相似度来计算：

~~~scala
import org.jblas.DoubleMatrix

/* Compute the cosine similarity between two vectors */
def cosineSimilarity(vec1: DoubleMatrix, vec2: DoubleMatrix): Double = {
  vec1.dot(vec2) / (vec1.norm2() * vec2.norm2())
}
~~~

以2055商品为例，计算实际评分和预测评分相似度

~~~scala
val itemId = 2055
val itemFactor = model.productFeatures.lookup(itemId).head
//itemFactor: Array[Double] = Array(0.3660752773284912, 0.43573060631752014, -0.3421429991722107, 0.44382765889167786, -1.4875195026397705, 0.6274569630622864, -0.3264533579349518, -0.9939845204353333, -0.8710321187973022, -0.7578890323638916, -0.14621856808662415, -0.7254264950752258)
val itemVector = new DoubleMatrix(itemFactor)
//itemVector: org.jblas.DoubleMatrix = [0.366075; 0.435731; -0.342143; 0.443828; -1.487520; 0.627457; -0.326453; -0.993985; -0.871032; -0.757889; -0.146219; -0.725426]

cosineSimilarity(itemVector, itemVector)
// res99: Double = 0.9999999999999999
~~~

找到和该商品最相似的10个商品：

~~~scala
val sims = model.productFeatures.map{ case (id, factor) =>
  val factorVector = new DoubleMatrix(factor)
  val sim = cosineSimilarity(factorVector, itemVector)
  (id, sim)
}
val sortedSims = sims.top(K)(Ordering.by[(Int, Double), Double] { case (id, similarity) => similarity })
//sortedSims: Array[(Int, Double)] = Array((2055,0.9999999999999999), (2051,0.9138311231145874), (3520,0.8739823400539756), (2190,0.8718466671129721), (2050,0.8612639515847019), (1011,0.8466911667526461), (2903,0.8455764332511272), (3121,0.8227325520485377), (3674,0.8075743004357392), (2016,0.8063817280259447))
println(sortedSims.mkString("\n"))
//    (2055,0.9999999999999999)
//    (2051,0.9138311231145874)
//    (3520,0.8739823400539756)
//    (2190,0.8718466671129721)
//    (2050,0.8612639515847019)
//    (1011,0.8466911667526461)
//    (2903,0.8455764332511272)
//    (3121,0.8227325520485377)
//    (3674,0.8075743004357392)
//    (2016,0.8063817280259447)
~~~

显然第一个最相似的商品即为该商品本身，即2055，我们可以修改下代码，取前k+1个商品，然后排除第一个：

~~~scala
val sortedSims2 = sims.top(K + 1)(Ordering.by[(Int, Double), Double] { case (id, similarity) => similarity })
//sortedSims2: Array[(Int, Double)] = Array((2055,0.9999999999999999), (2051,0.9138311231145874), (3520,0.8739823400539756), (2190,0.8718466671129721), (2050,0.8612639515847019), (1011,0.8466911667526461), (2903,0.8455764332511272), (3121,0.8227325520485377), (3674,0.8075743004357392), (2016,0.8063817280259447), (3672,0.8016276723120674))

sortedSims2.slice(1, 11).map{ case (id, sim) => (id, sim) }.mkString("\n")
//    (2051,0.9138311231145874)
//    (3520,0.8739823400539756)
//    (2190,0.8718466671129721)
//    (2050,0.8612639515847019)
//    (1011,0.8466911667526461)
//    (2903,0.8455764332511272)
//    (3121,0.8227325520485377)
//    (3674,0.8075743004357392)
//    (2016,0.8063817280259447)
//    (3672,0.8016276723120674)
~~~

接下来，我们可以计算给该用户推荐的前K个商品的平均准确度MAPK，该算法定义如下（该算法是否正确还有待考证）：

~~~scala
/* Function to compute average precision given a set of actual and predicted ratings */
// Code for this function is based on: https://github.com/benhamner/Metrics
def avgPrecisionK(actual: Seq[Int], predicted: Seq[Int], k: Int): Double = {
  val predK = predicted.take(k)
  var score = 0.0
  var numHits = 0.0
  for ((p, i) <- predK.zipWithIndex) {
    if (actual.contains(p)) {
      numHits += 1.0
      score += numHits / (i.toDouble + 1.0)
    }
  }
  if (actual.isEmpty) {
    1.0
  } else {
    score / scala.math.min(actual.size, k).toDouble
  }
}
~~~

给该用户推荐的商品为：

~~~scala
val actualProducts = productsForUser.map(_.product)
//actualProducts: Seq[Int] = ArrayBuffer(2055, 1197, 593, 599, 673, 3037, 1381, 1610, 3074, 204, 3508, 1007, 260, 3487, 3494, 1201, 3671, 1207, 2947, 2951, 2896, 1304)
~~~

给该用户预测的商品为：

~~~scala
 val predictedProducts = topKRecs.map(_.product)
//predictedProducts: Array[Int] = Array(2545, 129, 184, 811, 1421, 1313, 2892, 2483, 397, 97)
~~~

最后的准确度为：

~~~scala
val apk10 = avgPrecisionK(actualProducts, predictedProducts, 10)
// apk10: Double = 0.0
~~~

# 批量推荐

你可以评分记录中获得所有用户然后依次给每个用户推荐：

~~~scala
val users = ratings.map(_.user).distinct()

users.collect.flatMap { user =>
  model.recommendProducts(user, 10)
}
~~~

这种方式是遍历内存中的一个集合然后循环调用RDD的操作，运行会比较慢，另外一种方式是直接操作model中的userFeatures和productFeatures，代码如下：

~~~scala
val itemFactors = model.productFeatures.map { case (id, factor) => factor }.collect()
val itemMatrix = new DoubleMatrix(itemFactors)
println(itemMatrix.rows, itemMatrix.columns)
//(3706,12)

// broadcast the item factor matrix
val imBroadcast = sc.broadcast(itemMatrix)

//获取商品和索引的映射
var idxProducts=model.productFeatures.map { case (prodcut, factor) => prodcut }.zipWithIndex().map{case (prodcut, idx) => (idx,prodcut)}.collectAsMap()
val idxProductsBroadcast = sc.broadcast(idxProducts)

val allRecs = model.userFeatures.map{ case (user, array) =>
  val userVector = new DoubleMatrix(array)
  val scores = imBroadcast.value.mmul(userVector)
  val sortedWithId = scores.data.zipWithIndex.sortBy(-_._1)
  //根据索引取对应的商品id
  val recommendedProducts = sortedWithId.map(_._2).map{idx=>idxProductsBroadcast.value.get(idx).get}
  (user, recommendedProducts) 
}
~~~

这种方式其实还不是最优方法，更好的方法可以参考[Personalised recommendations using Spark](http://www.alesisnovik.com/?p=8)，当然这篇文章中的代码还可以继续优化一下。我修改后的代码如下，供大家参考：

~~~scala
val productFeatures = model.productFeatures.collect()
var productArray = ArrayBuffer[Int]()
var productFeaturesArray = ArrayBuffer[Array[Double]]()
for ((product, features) <- productFeatures) {
  productArray += product
  productFeaturesArray += features
}

val productArrayBroadcast = sc.broadcast(productArray)
val productFeatureMatrixBroadcast = sc.broadcast(new DoubleMatrix(productFeaturesArray.toArray).transpose())

start = System.currentTimeMillis()
val allRecs = model.userFeatures.mapPartitions { iter =>
  // Build user feature matrix for jblas
  var userFeaturesArray = ArrayBuffer[Array[Double]]()
  var userArray = new ArrayBuffer[Int]()
  while (iter.hasNext) {
    val (user, features) = iter.next()
    userArray += user
    userFeaturesArray += features
  }

  var userFeatureMatrix = new DoubleMatrix(userFeaturesArray.toArray)
  var userRecommendationMatrix = userFeatureMatrix.mmul(productFeatureMatrixBroadcast.value)
  var productArray=productArrayBroadcast.value
  var mappedUserRecommendationArray = new ArrayBuffer[String](params.topk)

  // Extract ratings from the matrix
  for (i <- 0 until userArray.length) {
    var ratingSet =  mutable.TreeSet.empty(Ordering.fromLessThan[(Int,Double)](_._2 > _._2))
    for (j <- 0 until productArray.length) {
      var rating = (productArray(j), userRecommendationMatrix.get(i,j))
      ratingSet += rating
    }
    mappedUserRecommendationArray += userArray(i)+","+ratingSet.take(params.topk).mkString(",")
  }
  mappedUserRecommendationArray.iterator
}
~~~

>2015.06.12 更新：
> 
> 悲哀的是，上面的方法还是不能解决问题，因为矩阵相乘会撑爆集群内存；可喜的是，如果你关注Spark最新动态，你会发现Spark1.4.0中MatrixFactorizationModel提供了`recommendForAll`方法实现离线批量推荐，详细说明见[SPARK-3066](https://issues.apache.org/jira/browse/SPARK-3066)。因为，我使用的Hadoop版本是CDH-5.4.0，其中Spark版本还是1.3.0，所以暂且不能在集群上测试Spark1.4.0中添加的新方法。

`如果上面结果跑出来了，就可以验证推荐结果是否正确`。还是以384用户为例：

~~~scala
allRecs.lookup(384).head.take(10)
//res50: Array[Int] = Array(1539, 219, 1520, 775, 3161, 2711, 2503, 771, 853, 759)
topKRecs.map(_.product)
//res49: Array[Int] = Array(1539, 219, 1520, 775, 3161, 2711, 2503, 771, 853, 759)
~~~

接下来，我们可以计算所有推荐结果的准确度了，首先，得到每个用户评分过的所有商品：

~~~scala
val userProducts = ratings.map{ case Rating(user, product, rating) => (user, product) }.groupBy(_._1)
~~~

然后，预测的商品和实际商品关联求准确度：

~~~scala
// finally, compute the APK for each user, and average them to find MAPK
val MAPK = allRecs.join(userProducts).map{ case (userId, (predicted, actualWithIds)) =>
  val actual = actualWithIds.map(_._2).toSeq
  avgPrecisionK(actual, predicted, K)
}.reduce(_ + _) / allRecs.count
println("Mean Average Precision at K = " + MAPK)
//Mean Average Precision at K = 0.018827551771260383
~~~

其实，我们也可以使用Spark内置的算法计算RMSE和MAE：

~~~scala
// MSE, RMSE and MAE
import org.apache.spark.mllib.evaluation.RegressionMetrics

val predictedAndTrue = ratesAndPreds.map { case ((user, product), (actual, predicted)) => (actual, predicted) }
val regressionMetrics = new RegressionMetrics(predictedAndTrue)
println("Mean Squared Error = " + regressionMetrics.meanSquaredError)
println("Root Mean Squared Error = " + regressionMetrics.rootMeanSquaredError)
// Mean Squared Error = 0.5490153087908566
// Root Mean Squared Error = 0.7409556726220918

// MAPK
import org.apache.spark.mllib.evaluation.RankingMetrics
val predictedAndTrueForRanking = allRecs.join(userProducts).map{ case (userId, (predicted, actualWithIds)) =>
  val actual = actualWithIds.map(_._2)
  (predicted.toArray, actual.toArray)
}
val rankingMetrics = new RankingMetrics(predictedAndTrueForRanking)
println("Mean Average Precision = " + rankingMetrics.meanAveragePrecision)
// Mean Average Precision = 0.04417535679520426
~~~

计算推荐2000个商品时的准确度为：

~~~scala
val MAPK2000 = allRecs.join(userProducts).map{ case (userId, (predicted, actualWithIds)) =>
  val actual = actualWithIds.map(_._2).toSeq
  avgPrecisionK(actual, predicted, 2000)
}.reduce(_ + _) / allRecs.count
println("Mean Average Precision = " + MAPK2000)
//Mean Average Precision = 0.025228311843069083
~~~

# 保存和加载推荐模型

对与实时推荐，我们需要启动一个web server，在启动的时候生成或加载训练模型，然后提供API接口返回推荐接口，需要调用的相关方法为：

~~~scala
save(model: MatrixFactorizationModel, path: String)
load(sc: SparkContext, path: String)
~~~

model中的userFeatures和productFeatures也可以保存起来：

~~~scala
val outputDir="/tmp"
model.userFeatures.map{ case (id, vec) => id + "\t" + vec.mkString(",") }.saveAsTextFile(outputDir + "/userFeatures")
model.productFeatures.map{ case (id, vec) => id + "\t" + vec.mkString(",") }.saveAsTextFile(outputDir + "/productFeatures")
~~~

# 总结

本文主要记录如何使用ALS算法实现协同过滤并给用户推荐商品，以上代码在[Github](https://github.com/javachen/learning-spark/tree/master/src/main/scala/com/javachen/examples/mllib)仓库中的ScalaLocalALS.scala文件。

如果你想更加深入了解Spark MLlib算法的使用，可以看看[Packt.Machine Learning with Spark.2015.pdf](http://f.dataguru.cn/thread-495493-1-1.html)这本电子书并下载书中的源码，本文大部分代码参考自该电子书。

# 参考资料

- [Spark MLlib中的协同过滤](/2015/04/17-mllib-collaborative-filtering)
- [Packt.Machine Learning with Spark.2015.pdf](http://f.dataguru.cn/thread-495493-1-1.html)
- [SPARK-3066](https://issues.apache.org/jira/browse/SPARK-3066)
