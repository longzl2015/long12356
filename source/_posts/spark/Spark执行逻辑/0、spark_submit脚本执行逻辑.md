---
title: spark0-spark_submit脚本执行逻辑
date: 2018-06-04 23:22:58
tags: 
  - spark
categories:
  - spark
---

# spark-submit分析

spark-submit 脚本的主要流程:

1. 执行 `./bin/spark-submit`文件
    - 设置 Spark_home, 关闭字符串的随机Hash，调用 `./bin/spark-class`

2. 执行 `./bin/spark-class`文件
    - 执行`./bin/load-spark-env.sh`: 设置 Spark_home，执行 `./conf/spark-env.sh`，scala版本号和scala主目录
    - 设置 Spark_home
    - 获取 java_home 或者 确认 java指令 能够使用
    - 设置 将spark的相关jar包和scala的相关jar 设置到 LAUNCH_CLASSPATH 添加到中
    - 最终执行 `java -Xmx128m -cp "$LAUNCH_CLASSPATH" org.apache.spark.launcher.Main + 相关参数`
    
##1 spark-submit脚本内容

这个脚本较为简单，将参数传递给spark-class运行
`$@` ： 表示传给脚本的所有参数的列表

```bash
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

# disable randomized hash for string in Python 3.3+
# 对同一个字符串，多次产生的hash值相同。
export PYTHONHASHSEED=0

# spark-shell传入的参数为 --class org.apache.spark.repl.Main --name "Spark shell" "$@"
exec "${SPARK_HOME}"/bin/spark-class org.apache.spark.deploy.SparkSubmit "$@"

```

##2 spark-class脚本内容
分析spark-class的逻辑之前，先看看spark-env.sh的实现内容。

### 2.1 spark-env.sh

主要定义spark-env.sh中的变量、scala版本号和scala主目录。

```bash
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

if [ -z "$SPARK_ENV_LOADED" ]; then
  export SPARK_ENV_LOADED=1

  # Returns the parent of the directory this script lives in.
  parent_dir="${SPARK_HOME}"

  user_conf_dir="${SPARK_CONF_DIR:-"$parent_dir"/conf}"

  if [ -f "${user_conf_dir}/spark-env.sh" ]; then
    # Promote all variable declarations to environment (exported) variables
    set -a
    . "${user_conf_dir}/spark-env.sh"
    set +a
  fi
fi

# Setting SPARK_SCALA_VERSION if not already set.

if [ -z "$SPARK_SCALA_VERSION" ]; then

  ASSEMBLY_DIR2="${SPARK_HOME}/assembly/target/scala-2.11"
  ASSEMBLY_DIR1="${SPARK_HOME}/assembly/target/scala-2.10"

  if [[ -d "$ASSEMBLY_DIR2" && -d "$ASSEMBLY_DIR1" ]]; then
    echo -e "Presence of build for both scala versions(SCALA 2.10 and SCALA 2.11) detected." 1>&2
    echo -e 'Either clean one of them or, export SPARK_SCALA_VERSION=2.11 in spark-env.sh.' 1>&2
    exit 1
  fi

  if [ -d "$ASSEMBLY_DIR2" ]; then
    export SPARK_SCALA_VERSION="2.11"
  else
    export SPARK_SCALA_VERSION="2.10"
  fi
fi
```

### 2.2 spark-class具体内容

```bash
#定位spark主目录
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

#加载load-spark-env.sh，运行环境相关信息
#例如配置文件conf下的spark-env.sh等
. "${SPARK_HOME}"/bin/load-spark-env.sh

# Find the java binary
if [ -n "${JAVA_HOME}" ]; then
  RUNNER="${JAVA_HOME}/bin/java"
else
  if [ `command -v java` ]; then
    RUNNER="java"
  else
    echo "JAVA_HOME is not set" >&2
    exit 1
  fi
fi

# Find assembly jar
# 定位spark-assembly-1.5.0-hadoop2.4.0.jar文件（以spark1.5.0为例）
#这意味着任务提交时无需将该JAR文件打包
SPARK_ASSEMBLY_JAR=
if [ -f "${SPARK_HOME}/RELEASE" ]; then
  ASSEMBLY_DIR="${SPARK_HOME}/lib"
else
  ASSEMBLY_DIR="${SPARK_HOME}/assembly/target/scala-$SPARK_SCALA_VERSION"
fi

GREP_OPTIONS=
num_jars="$(ls -1 "$ASSEMBLY_DIR" | grep "^spark-assembly.*hadoop.*\.jar$" | wc -l)"
# 判断是 spark 是否已经编译
if [ "$num_jars" -eq "0" -a -z "$SPARK_ASSEMBLY_JAR" -a "$SPARK_PREPEND_CLASSES" != "1" ]; then
  echo "Failed to find Spark assembly in $ASSEMBLY_DIR." 1>&2
  echo "You need to build Spark before running this program." 1>&2
  exit 1
fi
# Spark assembly jars只能存在一个
if [ -d "$ASSEMBLY_DIR" ]; then
  ASSEMBLY_JARS="$(ls -1 "$ASSEMBLY_DIR" | grep "^spark-assembly.*hadoop.*\.jar$" || true)"
  if [ "$num_jars" -gt "1" ]; then
    echo "Found multiple Spark assembly jars in $ASSEMBLY_DIR:" 1>&2
    echo "$ASSEMBLY_JARS" 1>&2
    echo "Please remove all but one jar." 1>&2
    exit 1
  fi
fi
# 获得ASSEMBLY_JAR路径
SPARK_ASSEMBLY_JAR="${ASSEMBLY_DIR}/${ASSEMBLY_JARS}"

LAUNCH_CLASSPATH="$SPARK_ASSEMBLY_JAR"

# Add the launcher build dir to the classpath if requested.
if [ -n "$SPARK_PREPEND_CLASSES" ]; then
  LAUNCH_CLASSPATH="${SPARK_HOME}/launcher/target/scala-$SPARK_SCALA_VERSION/classes:$LAUNCH_CLASSPATH"
fi

export _SPARK_ASSEMBLY="$SPARK_ASSEMBLY_JAR"

# For tests
if [[ -n "$SPARK_TESTING" ]]; then
  unset YARN_CONF_DIR
  unset HADOOP_CONF_DIR
fi

# The launcher library will print arguments separated by a NULL character, to allow arguments with
# characters that would be otherwise interpreted by the shell. Read that in a while loop, populating
# an array that will be used to exec the final command.
# 执行org.apache.spark.launcher.Main作为Spark应用程序的主入口
CMD=()
while IFS= read -d '' -r ARG; do
  CMD+=("$ARG")
## java -cp 指定这个class文件所需要的所有类的包路径-即系统类加载器的路径（涉及到类加载机制）
done < <("$RUNNER" -cp "$LAUNCH_CLASSPATH" org.apache.spark.launcher.Main "$@")
exec "${CMD[@]}"
```
最终运行为：

```bash
java -cp ${SPARK_HOME}/launcher/target/scala-$SPARK_SCALA_VERSION/classes:$LAUNCH_CLASSPATH" org.apache.spark.launcher.Main org.apache.spark.deploy.SparkSubmit --class org.apache.spark.repl.Main --name "Spark shell" "$@"
```
[参考](http://blog.csdn.net/lovehuangjiaju/article/details/49123975)


