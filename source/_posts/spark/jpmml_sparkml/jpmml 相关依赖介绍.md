---

title: jpmml相关依赖介绍

date: 2019-09-13 16:50:00

categories: [spark,sparkml]

tags: [jpmml,sparkml]

---

jpmml相关依赖介绍

<!--more-->


### jpmml-sparkml 

主要作用: 将 spark ML pipelines 转换为 PMML。 

https://github.com/jpmml/jpmml-sparkml/tree/1.4.11

包含依赖 

jpmml-converter 1.3.9  



### JPMML-XGBoost

主要作用: 将 XGBoost 模型 转换为 PMML

https://github.com/jpmml/jpmml-xgboost/blob/1.3.5/pom.xml

包含依赖:

jpmml-converter 1.3.5


### xgboost4j-spark

主要作用: 以spark的方式运行 XGBoost

包含依赖:

xgboost4j 0.82

