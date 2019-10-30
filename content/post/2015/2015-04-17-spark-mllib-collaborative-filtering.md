---
layout: post

title: Spark MLlib中的协同过滤
date: 2015-04-17T08:00:00+08:00

categories: [ spark ]

tags: [ spark,mllib,recommendation,als]

description: 本文主要通过Spark官方的例子理解ALS协同过滤算法的原理和编码过程，然后通过对电影进行推荐来熟悉一个完整的推荐过程。

published: true

---

本文主要通过Spark官方的例子理解ALS协同过滤算法的原理和编码过程，然后通过对电影进行推荐来熟悉一个完整的推荐过程。

# 协同过滤

[协同过滤](http://en.wikipedia.org/wiki/Recommender_system#Collaborative_filtering)常被应用于推荐系统，旨在补充用户-商品关联矩阵中所缺失的部分。MLlib当前支持基于模型的协同过滤，其中用户和商品通过一小组隐语义因子进行表达，并且这些因子也用于预测缺失的元素。Spark MLlib实现了[交替最小二乘法](http://dl.acm.org/citation.cfm?id=1608614)(ALS) 来学习这些隐性语义因子。

在 MLlib 中的实现类为org.apache.spark.mllib.recommendation.ALS.scala，其有如下的参数:

- `numUserBlocks`：是用于并行化计算的分块个数 (设置为-1，为自动配置)。
- `numProductBlocks`：是用于并行化计算的分块个数 (设置为-1，为自动配置)。
- `rank`：是模型中隐语义因子的个数。
- `iterations`：是迭代的次数，推荐值：10-20。
- `lambda`：惩罚函数的因数，是ALS的正则化参数，推荐值：0.01。
- `implicitPrefs`：决定了是用显性反馈ALS的版本还是用适用隐性反馈数据集的版本。
- `alpha`：是一个针对于隐性反馈 ALS 版本的参数，这个参数决定了偏好行为强度的基准。
- `seed`：随机种子

可以调整这些参数，不断优化结果，使均方差变小。比如：iterations越多，lambda较小，均方差会较小，推荐结果较优。

提供以下方法：

~~~scala
def run(ratings: RDD[Rating]): MatrixFactorizationModel

def train(ratings: RDD[Rating],rank: Int,iterations: Int,lambda: Double,blocks: Int,seed: Long): MatrixFactorizationModel
def train(ratings: RDD[Rating],rank: Int,iterations: Int,lambda: Double,blocks: Int): MatrixFactorizationModel
def train(ratings: RDD[Rating], rank: Int, iterations: Int, lambda: Double): MatrixFactorizationModel
def train(ratings: RDD[Rating], rank: Int, iterations: Int): MatrixFactorizationModel

def trainImplicit(ratings: RDD[Rating],rank: Int,iterations: Int,lambda: Double,blocks: Int,alpha: Double,seed: Long): MatrixFactorizationModel
def trainImplicit(ratings: RDD[Rating],rank: Int,iterations: Int,lambda: Double,blocks: Int,alpha: Double): MatrixFactorizationModel
def trainImplicit(ratings: RDD[Rating], rank: Int, iterations: Int, lambda: Double, alpha: Double): MatrixFactorizationModel
def trainImplicit(ratings: RDD[Rating], rank: Int, iterations: Int): MatrixFactorizationModel
~~~

以上所有方法需要一个参数Rating，其为一个包括三个元素的 case class：

~~~scala
case class Rating(user: Int, product: Int, rating: Double)
~~~

另外，以上方法均返回MatrixFactorizationModel类型的对象，提供以下方法：

~~~scala
/** Predict the rating of one user for one product. */
def predict(user: Int, product: Int): Double

/**Predict the rating of many users for many products.*/
def predict(usersProducts: RDD[(Int, Int)]): RDD[Rating]

// Recommends products to a user.
def recommendProducts(user: Int, num: Int): Array[Rating]

//Recommends users to a product.
def recommendUsers(product: Int, num: Int): Array[Rating]

def save(sc: SparkContext, path: String): Unit

def load(sc: SparkContext, path: String): MatrixFactorizationModel =
~~~


## 隐性反馈 vs 显性反馈

基于矩阵分解的协同过滤的标准方法一般将用户商品矩阵中的元素作为用户对商品的显性偏好。
在许多的现实生活中的很多场景中，我们常常只能接触到隐性的反馈（例如游览，点击，购买，喜欢，分享等等）在 MLlib 中所用到的处理这种数据的方法来源于文献： [Collaborative Filtering for Implicit Feedback Datasets](http://labs.yahoo.com/files/HuKorenVolinsky-ICDM08.pdf)。 本质上，这个方法将数据作为二元偏好值和偏好强度的一个结合，而不是对评分矩阵直接进行建模。因此，评价就不是与用户对商品的显性评分而是和所观察到的用户偏好强度关联了起来。然后，这个模型将尝试找到隐语义因子来预估一个用户对一个商品的偏好。

# 代码示例

下面例子来自<http:/.apache.org/docs/latest/mllib-collaborative-filtering.html>，并做了稍许修改。

## Scala 示例

为了测试简单，使用Spark本地运行模式进行测试。下面代码可以在spark-shell中运行：

~~~scala
import org.apache.spark.mllib.recommendation.ALS
import org.apache.spark.mllib.recommendation.MatrixFactorizationModel
import org.apache.spark.mllib.recommendation.Rating

// Load and parse the data
val data = sc.textFile("data/mllib/als/test.data")
val ratings = data.map(_.split(',') match { case Array(user, item, rate) =>
    Rating(user.toInt, item.toInt, rate.toDouble)
  })

// Build the recommendation model using ALS
val rank = 10
val numIterations = 20
val model = ALS.train(ratings, rank, numIterations, 0.01)

// Evaluate the model on rating data
val usersProducts = ratings.map { case Rating(user, product, rate) =>
  (user, product)
}
val predictions = 
  model.predict(usersProducts).map { case Rating(user, product, rate) => 
    ((user, product), rate)
  }
val ratesAndPreds = ratings.map { case Rating(user, product, rate) => 
  ((user, product), rate)
}.join(predictions)
val MSE = ratesAndPreds.map { case ((user, product), (r1, r2)) => 
  val err = (r1 - r2)
  err * err
}.mean()
println("Mean Squared Error = " + MSE)

// Save and load model
model.save(sc, "myModelPath")
val sameModel = MatrixFactorizationModel.load(sc, "myModelPath")
~~~

## Java示例

~~~java
import scala.Tuple2;

import org.apache.spark.api.java.*;
import org.apache.spark.api.java.function.Function;
import org.apache.spark.mllib.recommendation.ALS;
import org.apache.spark.mllib.recommendation.MatrixFactorizationModel;
import org.apache.spark.mllib.recommendation.Rating;
import org.apache.spark.SparkConf;

public class JavaALS {
  public static void main(String[] args) {
    SparkConf conf = new SparkConf().setAppName("Collaborative Filtering Example");
    JavaSparkContext sc = new JavaSparkContext(conf);

    // Load and parse the data
    String path = "data/mllib/als/test.data";
    JavaRDD<String> data = sc.textFile(path);
    JavaRDD<Rating> ratings = data.map(
      new Function<String, Rating>() {
        public Rating call(String s) {
          String[] sarray = s.split(",");
          return new Rating(Integer.parseInt(sarray[0]), Integer.parseInt(sarray[1]), 
                            Double.parseDouble(sarray[2]));
        }
      }
    );

    // Build the recommendation model using ALS
    int rank = 10;
    int numIterations = 20;
    float lambda = 0.01;
    MatrixFactorizationModel model = ALS.train(JavaRDD.toRDD(ratings), rank, numIterations, lambda); 

    // Evaluate the model on rating data
    JavaRDD<Tuple2<Object, Object>> userProducts = ratings.map(
      new Function<Rating, Tuple2<Object, Object>>() {
        public Tuple2<Object, Object> call(Rating r) {
          return new Tuple2<Object, Object>(r.user(), r.product());
        }
      }
    );
    JavaPairRDD<Tuple2<Integer, Integer>, Double> predictions = JavaPairRDD.fromJavaRDD(
      model.predict(JavaRDD.toRDD(userProducts)).toJavaRDD().map(
        new Function<Rating, Tuple2<Tuple2<Integer, Integer>, Double>>() {
          public Tuple2<Tuple2<Integer, Integer>, Double> call(Rating r){
            return new Tuple2<Tuple2<Integer, Integer>, Double>(
              new Tuple2<Integer, Integer>(r.user(), r.product()), r.rating());
          }
        }
    ));
    JavaRDD<Tuple2<Double, Double>> ratesAndPreds = 
      JavaPairRDD.fromJavaRDD(ratings.map(
        new Function<Rating, Tuple2<Tuple2<Integer, Integer>, Double>>() {
          public Tuple2<Tuple2<Integer, Integer>, Double> call(Rating r){
            return new Tuple2<Tuple2<Integer, Integer>, Double>(
              new Tuple2<Integer, Integer>(r.user(), r.product()), r.rating());
          }
        }
    )).join(predictions).values();
    double MSE = JavaDoubleRDD.fromRDD(ratesAndPreds.map(
      new Function<Tuple2<Double, Double>, Object>() {
        public Object call(Tuple2<Double, Double> pair) {
          Double err = pair._1() - pair._2();
          return err * err;
        }
      }
    ).rdd()).mean();
    System.out.println("Mean Squared Error = " + MSE);
  }
}
~~~

## Python示例

下面代码可以在 pyspark 中运行下面代码：

~~~python
from pyspark.mllib.recommendation import ALS
from numpy import array

# Load and parse the data
data = sc.textFile("data/mllib/als/test.data")
ratings = data.map(lambda line: array([float(x) for x in line.split(',')]))

# Build the recommendation model using Alternating Least Squares
rank = 10
numIterations = 20
model = ALS.train(ratings, rank, numIterations)

# Evaluate the model on training data
testdata = ratings.map(lambda p: (int(p[0]), int(p[1])))
predictions = model.predictAll(testdata).map(lambda r: ((r[0], r[1]), r[2]))
ratesAndPreds = ratings.map(lambda r: ((r[0], r[1]), r[2])).join(predictions)
MSE = ratesAndPreds.map(lambda r: (r[1][0] - r[1][1])**2).reduce(lambda x, y: x + y)/ratesAndPreds.count()
print("Mean Squared Error = " + str(MSE))
~~~

# 总结

使用Spark MLlib的ALS算法进行协同过滤，首先需要了解推荐的过程，然后需要根据测试不断修改训练测试，建立合理的模型，最后再给用户进行推荐商品，保存推荐结果。

另外，在网上找到一些Spark做推荐的项目：

- 提供Restfull接口的实时推荐：<https://github.com/OndraFiedler-recommender>
- spark-elasticsearch-mllib：<https://github.com/ebiznext-elasticsearch-mllib>
- Beyond Piwik Web Analytics：<https://github.com/skrusche63-piwik>
- Serves predictions via a REST API：<https://github.com/SeldonIO/seldon-server>
- <https://github.com/zhuixun/learningspark>
- Spark-Movie-Recommendation：<https://github.com/yuriy-voderatskiy/Spark-Movie-Recommendation>

更多关于推荐相关的资源可以参考[Reading List 2015-03](/2015/03/30/reading-list-2015-03.html)。

# 参考文章

- [Movie Recommendation with MLlib](https://databricks-training.s3.amazonaws.com/movie-recommendation-with-mllib.html)
- [Spark MLlib系列(二):基于协同过滤的电影推荐系统](http://blog.csdn.net/shifenglov/article/details/43795597)
- [ALSBenchmark.scala](https://github.com/gaapt/als_recom/blob/master/ALSBenchmarkSpark%2Fsrc%2Fmain%2Fscala%2FALSBenchmark.scala)
