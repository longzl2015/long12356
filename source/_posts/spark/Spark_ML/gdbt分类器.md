
---
title: gdbt分类器
date: 2017-06-04 23:22:58
tags: 
  - spark_ml
categories:
  - spark
---

# gdbt分类器

[TOC]

GBTClassifier文件中包含有两个class文件：GBTClassifier 和 GBTClassificationModel

##1、GBTClassifier

class GBTClassifier 继承自 Estimator ，由此可见，GBTClassifier完成的工作是模型的评估/训练，实现样本数据到模型的过程。

class GBTClassifier 主要方法有相关参数的设置方法、一个train方法和copy方法。

```scala
class GBTClassifier @Since("1.4.0") (
    @Since("1.4.0") override val uid: String)
  extends Predictor[Vector, GBTClassifier, GBTClassificationModel]
  with GBTClassifierParams with DefaultParamsWritable with Logging {

  override def setMaxDepth(value: Int): this.type = set(maxDepth, value)
  override def setMaxBins(value: Int): this.type = set(maxBins, value)
  override def setMinInstancesPerNode(value: Int): this.type = set(minInstancesPerNode, value)
  override def setMinInfoGain(value: Double): this.type = set(minInfoGain, value)
  override def setMaxMemoryInMB(value: Int): this.type = set(maxMemoryInMB, value)
  override def setCacheNodeIds(value: Boolean): this.type = set(cacheNodeIds, value)
  override def setCheckpointInterval(value: Int): this.type = set(checkpointInterval, value)
  override def setImpurity(value: String): this.type = {
    logWarning("GBTClassifier.setImpurity should NOT be used")
    this
  }
  override def setSubsamplingRate(value: Double): this.type = set(subsamplingRate, value)
  override def setSeed(value: Long): this.type = set(seed, value)
  override def setMaxIter(value: Int): this.type = set(maxIter, value)
  override def setStepSize(value: Double): this.type = set(stepSize, value)
  def setLossType(value: String): this.type = set(lossType, value)

  override protected def train(dataset: Dataset[_]): GBTClassificationModel = {
    val categoricalFeatures: Map[Int, Int] =
      MetadataUtils.getCategoricalFeatures(dataset.schema($(featuresCol)))
    val oldDataset: RDD[LabeledPoint] =
      dataset.select(col($(labelCol)), col($(featuresCol))).rdd.map {
        case Row(label: Double, features: Vector) =>
          require(label == 0 || label == 1, s"GBTClassifier was given" +
            s" dataset with invalid label $label.  Labels must be in {0,1}; note that" +
            s" GBTClassifier currently only supports binary classification.")
          LabeledPoint(label, features)
      }
    val numFeatures = oldDataset.first().features.size
    val boostingStrategy = super.getOldBoostingStrategy(categoricalFeatures, OldAlgo.Classification)

    val instr = Instrumentation.create(this, oldDataset)
    instr.logParams(params: _*)
    instr.logNumFeatures(numFeatures)
    instr.logNumClasses(2)

    val (baseLearners, learnerWeights) = GradientBoostedTrees.run(oldDataset, boostingStrategy,
      $(seed))
    val m = new GBTClassificationModel(uid, baseLearners, learnerWeights, numFeatures)
    instr.logSuccess(m)
    m
  }

  @Since("1.4.1")
  override def copy(extra: ParamMap): GBTClassifier = defaultCopy(extra)
}

```



## 二、GBTClassificationModel

GBTClassificationModel 继承自 PredictionModel，一个 Transformer，完成 DataFrame 到 DataFrame 的转换。

GBTClassificationModel中比较重要的方法是 transformImpl() 和 predict()。

transformImpl方法主要完成的功能是将 featuresCol数据 进行相关计算，得到 predict值，并将该值储存为新列。

需要注意的是，gdbt中 最终得到的 predict值 会是 1 或 0，无法得到 预测分数值。

```scala
  override protected def transformImpl(dataset: Dataset[_]): DataFrame = {
    val bcastModel = dataset.sparkSession.sparkContext.broadcast(this)
    val predictUDF = udf { (features: Any) =>
      bcastModel.value.predict(features.asInstanceOf[Vector])
    }
    dataset.withColumn($(predictionCol), predictUDF(col($(featuresCol))))
  }

  override protected def predict(features: Vector): Double = {
    // TODO: When we add a generic Boosting class, handle transform there?  SPARK-7129
    // Classifies by thresholding sum of weighted tree predictions
    val treePredictions = _trees.map(_.rootNode.predictImpl(features).prediction)
    val prediction = blas.ddot(numTrees, treePredictions, 1, _treeWeights, 1)
    if (prediction > 0.0) 1.0 else 0.0
  }
```



