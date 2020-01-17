---

title: 启动jar

date: 2018-08-21 15:18:00

categories: [语言,java,命令行]

tags: [java,命令行]

---

java 启动脚本

<!--more-->


```bash
#!/bin/sh

basePath=`dirname $0`
cd ${basePath}

if [ ! -d "./tmp" ]; then
  mkdir ./tmp
fi

JAVA_OPTS="-Dloader.path='conf' -XX:MetaspaceSize=512m -XX:MaxMetaspaceSize=1024m -Xms1024m -Xmx4096m -Djava.io.tmpdir=./tmp"


app=`ls | grep app-`
echo "==== start new app"
echo ${app}

nohup java ${JAVA_OPTS} -jar app-*.jar --spring.profiles.active=prod &

echo 不建议使用 tailf nohup.out
echo 建议使用 tailf log/dm.log 观察应用是否启动成功
```