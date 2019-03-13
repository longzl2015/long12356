---

title: xgboost 

date: 2019-03-13 13:40:00

categories: [xgboost]

tags: [xgboost]

---





<!--more-->


## xgboost pmml output 字段问题

1. xgboost 在生成 miningMode 时，会将 mathContext设置为float。(org.jpmml.xgboost.ObjFunction.createMiningModel(..))
2. xgboost 在生成 output 中的 xgbValue 字段时，字段类型为 float 类型。
3. xgboost 在生成 output 中的 probability(0)和probability(1)字段时，根据 mathContext类型设置字段类型。(org.jpmml.converter.ModelUtil.createProbabilityOutput(..))

4. jpmml-spark 在 生成output中的probability(0)和probability(1)字段，字段类型为 double。(org.jpmml.sparkml.ClassificationModelConverter.registerOutputFields(..))

上述过程 生成了 相同的 probability(0)。在pmml生成阶段会报错，删除其中 3 生成的字段即可。



