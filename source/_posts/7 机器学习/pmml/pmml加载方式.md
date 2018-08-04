---
title: pmml 使用方式
tags: 
  - pmml
categories:
  - 机器学习
---


## java载入模型并预测

采用 [jpmml/jpmml-evaluator](http://link.zhihu.com/?target=https%3A//github.com/jpmml/jpmml-evaluator)项目，载入 PMML 文件，然后准备线上所需数据，示例代码如下：

```java
//准备画像数据－key和原始特征一致即可，key为特征字段
lrHeartInputMap.put("sbp", 142);
lrHeartInputMap.put("tobacco", 2);
lrHeartInputMap.put("ldl", 3);
lrHeartInputMap.put("adiposity", 30);
lrHeartInputMap.put("famhist", "Present");
lrHeartInputMap.put("typea", 83);
lrHeartInputMap.put("obesity", 23);
lrHeartInputMap.put("alcohol", 90);
lrHeartInputMap.put("age", 30);

//预测核心代码
public static void predictLrHeart() throws Exception {

    PMML pmml;
    //模型导入
    File file = new File("lrHeart.xml");
    InputStream inputStream = new FileInputStream(file);
    try (InputStream is = inputStream) {
        pmml = org.jpmml.model.PMMLUtil.unmarshal(is);

        ModelEvaluatorFactory modelEvaluatorFactory = ModelEvaluatorFactory.newInstance();
        ModelEvaluator<?> modelEvaluator = modelEvaluatorFactory.newModelEvaluator(pmml);
        Evaluator evaluator = (Evaluator) modelEvaluator;
        //获得模型中的特征字段
        List<InputField> inputFields = evaluator.getInputFields();
        //过模型的原始特征，从画像中获取数据，作为模型输入
        Map<FieldName, FieldValue> arguments = new LinkedHashMap<>();
        for (InputField inputField : inputFields) {
            FieldName inputFieldName = inputField.getName();
            Object rawValue = lrHeartInputMap.get(inputFieldName.getValue());
            FieldValue inputFieldValue = inputField.prepare(rawValue);
            arguments.put(inputFieldName, inputFieldValue);
        }

        Map<FieldName, ?> results = evaluator.evaluate(arguments);
        List<TargetField> targetFields = evaluator.getTargetFields();
        //获得结果，作为回归预测的例子，只有一个输出。对于分类问题等有多个输出。
        for (TargetField targetField : targetFields) {
            FieldName targetFieldName = targetField.getName();
            Object targetFieldValue = results.get(targetFieldName);
            System.out.println("target: " + targetFieldName.getValue() + " value: " + targetFieldValue);
        }
    }
}
```

## spark载入模型并预测

### pmml文件

以下pmml文件是由一个svm模型构建的，其输入有三个字段，有一个目标输出

```Xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>  
<PMML version="4.2" xmlns="http://www.dmg.org/PMML-4_2">  
    <Header description="linear SVM">  
        <Application name="Apache Spark MLlib"/>  
        <Timestamp>2016-11-16T22:17:47</Timestamp>  
    </Header>  
    <DataDictionary numberOfFields="4">  
        <DataField name="field_0" optype="continuous" dataType="double"/>  
        <DataField name="field_1" optype="continuous" dataType="double"/>  
        <DataField name="field_2" optype="continuous" dataType="double"/>  
        <DataField name="target" optype="categorical" dataType="string"/>  
    </DataDictionary>  
    <RegressionModel modelName="linear SVM" functionName="classification" normalizationMethod="none">  
        <MiningSchema>  
            <MiningField name="field_0" usageType="active"/>  
            <MiningField name="field_1" usageType="active"/>  
            <MiningField name="field_2" usageType="active"/>  
            <MiningField name="target" usageType="target"/>  
        </MiningSchema>  
        <RegressionTable intercept="0.0" targetCategory="1">  
            <NumericPredictor name="field_0" coefficient="-0.36682158807862086"/>  
            <NumericPredictor name="field_1" coefficient="3.8787681305811765"/>  
            <NumericPredictor name="field_2" coefficient="-1.6134308474471166"/>  
        </RegressionTable>  
        <RegressionTable intercept="0.0" targetCategory="0"/>  
    </RegressionModel>  
</PMML>  
```

### 测试数据

这个数据由列名和数据组成，这里需要注意，列名需要和pmml里面的列名对应；

```
field_0,field_1,field_2  
98,97,96  
1,2,7  

```



### 预测

```java
package org.jpmml.spark;  
  
import org.apache.hadoop.conf.Configuration;  
import org.apache.hadoop.fs.FileSystem;  
import org.apache.hadoop.fs.Path;  
import org.apache.spark.SparkConf;  
import org.apache.spark.api.java.JavaSparkContext;  
import org.apache.spark.ml.Transformer;  
import org.apache.spark.sql.*;  
import org.jpmml.evaluator.Evaluator;  
  
public class SVMEvaluationSparkExample {  
  
    static  
    public void main(String... args) throws Exception {  
  
        if(args.length != 3){  
            System.err.println("Usage: java " + SVMEvaluationSparkExample.class.getName() + " <PMML file> <Input file> <Output directory>");  
  
            System.exit(-1);  
        }  
        /** 
         * 根据pmml文件，构建模型 
         */  
        FileSystem fs = FileSystem.get(new Configuration());  
        Evaluator evaluator = EvaluatorUtil.createEvaluator(fs.open(new Path(args[0])));  
  
        TransformerBuilder modelBuilder = new TransformerBuilder(evaluator)  
                .withTargetCols()  
                .withOutputCols()  
                .exploded(true);  
  
        Transformer transformer = modelBuilder.build();  
  
        /** 
         * 利用DataFrameReader从原始数据中构造 DataFrame对象 
         * 需要原始数据包含列名 
         */  
        SparkConf conf = new SparkConf();  
        try(JavaSparkContext sparkContext = new JavaSparkContext(conf)){  
  
            SQLContext sqlContext = new SQLContext(sparkContext);  
  
            DataFrameReader reader = sqlContext.read()  
                    .format("com.databricks.spark.csv")  
                    .option("header", "true")  
                    .option("inferSchema", "true");  
            DataFrame dataFrame = reader.load(args[1]);// 输入数据需要包含列名  
  
            /** 
             * 使用模型进行预测 
             */  
            dataFrame = transformer.transform(dataFrame);  
  
            /** 
             * 写入数据 
             */  
            DataFrameWriter writer = dataFrame.write()  
                    .format("com.databricks.spark.csv")  
                    .option("header", "true");  
  
            writer.save(args[2]);  
        }  
    }  
}  
```



代码有四个部分，第一部分读取HDFS上面的PMML文件，然后构建模型；第二部分使用DataFrameReader根据输入数据构建DataFrame数据结构；第三部分，使用模型对构造的DataFrame数据进行预测；第四部分，把预测的结果写入HDFS。

注意里面在构造数据的时候.option("header","true")是一定要加的，原因如下：1）原始数据中确实有列名；2）如果这里不加，那么将读取不到列名的相关信息，将不能和模型中的列名对应；

