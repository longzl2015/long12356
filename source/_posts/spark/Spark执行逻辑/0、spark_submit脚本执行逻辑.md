---
title: spark0-spark_submit脚本执行逻辑
date: 2018-06-04 23:22:58
tags: 
  - spark
categories:
  - spark
---

# spark-submit分析

Spark-submit提交实例:

```bas
./bin/spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --master spark://192.168.1.20:7077 \
  --deploy-mode cluster \
  --supervise \
  --executor-memory 2G \
  --total-executor-cores 5 \
  /path/to/examples.jar \
  1000
```

spark-submit 脚本的主要流程:

1. 执行 `./bin/spark-submit`文件
    - 设置 Spark_home, 关闭字符串的随机Hash，调用 `./bin/spark-class`

2. 执行 `./bin/spark-class`文件
    - 执行`./bin/load-spark-env.sh`: 设置 Spark_home，执行 `./conf/spark-env.sh`，scala版本号和scala主目录
    - 设置 Spark_home
    - 获取 java_home 或者 确认 java指令 能够使用
    - 设置 将spark的相关jar包和scala的相关jar 设置到 LAUNCH_CLASSPATH 添加到中
    - 最终执行 `java -Xmx128m -cp "$LAUNCH_CLASSPATH" org.apache.spark.launcher.Main + 相关参数`
    
## spark-submit脚本内容

这个脚本较为简单，将参数传递给spark-class运行
`$@` ： 表示传给脚本的所有参数的列表

```bash
if [ -z "${SPARK_HOME}" ]; then
  export SPARK_HOME="$(cd "`dirname "$0"`"/..; pwd)"
fi

# disable randomized hash for string in Python 3.3+
# 对同一个字符串，多次产生的hash值相同。
export PYTHONHASHSEED=0

# 调用 ./bin/spark-class
exec "${SPARK_HOME}"/bin/spark-class org.apache.spark.deploy.SparkSubmit "$@"

```

## spark-class脚本内容
分析spark-class的逻辑之前，先看看spark-env.sh的实现内容。

### spark-env.sh

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

### spark-class具体内容

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
#
# The exit code of the launcher is appended to the output, so the parent shell removes it from the
# command array and checks the value to see if the launcher succeeded.
build_command() {
  "$RUNNER" -Xmx128m -cp "$LAUNCH_CLASSPATH" org.apache.spark.launcher.Main "$@"
  printf "%d\0" $?
}

# Turn off posix mode since it does not allow process substitution
set +o posix
CMD=()                                # 创建数组
while IFS= read -d '' -r ARG; do      # 把build_commands输出结果,循环加到数组CMD中
  CMD+=("$ARG")
done < <(build_command "$@")

COUNT=${#CMD[@]}                      # 数组长度
LAST=$((COUNT - 1))                   # 数组长度-1
LAUNCHER_EXIT_CODE=${CMD[$LAST]}      # 数组的最后一个值，也就是上边$?的值

# Certain JVM failures result in errors being printed to stdout (instead of stderr), which causes
# the code that parses the output of the launcher to get confused. In those cases, check if the
# exit code is an integer, and if it's not, handle it as a special error case.
# 某些JVM失败会导致错误被打印到stdout(而不是stderr)，这会导致解析启动程序输出的代码变得混乱。
# 在这些情况下，检查退出代码是否为整数，如果不是，将其作为特殊的错误处理。
if ! [[ $LAUNCHER_EXIT_CODE =~ ^[0-9]+$ ]]; then
  echo "${CMD[@]}" | head -n-1 1>&2
  exit 1
fi

# 如果返回值不为0，退出，返回返回值
if [ $LAUNCHER_EXIT_CODE != 0 ]; then
  exit $LAUNCHER_EXIT_CODE
fi

CMD=("${CMD[@]:0:$LAST}")     # CMD还是原来那些参数，$@
exec "${CMD[@]}"              # 执行这些

```

最终运行命令参考为：

```bash
/opt/jdk1.8/bin/java -Dhdp.version=2.6.0.3-8 -cp /usr/hdp/current/spark2-historyserver/conf/:/usr/hdp/2.6.0.3-8/spark2/jars/*:/usr/hdp/current/hadoop-client/conf/
   org.apache.spark.deploy.SparkSubmit \
  --master spark://192.168.1.20:7077 \
  --deploy-mode cluster \
  --class org.apache.spark.examples.SparkPi \
  --executor-memory 2G \
  --total-executor-cores 5 \
  ../examples/jars/spark-examples_2.11-2.1.0.2.6.0.3-8.jar \
  1000
```

## 参考 

[Spark源码阅读: Spark Submit任务提交](http://www.louisvv.com/archives/1340.html)

[Spark修炼之道（高级篇）——Spark源码阅读：第一节 Spark应用程序提交流程](http://blog.csdn.net/lovehuangjiaju/article/details/49123975)


