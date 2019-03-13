---

title: spark使用kryo序列化

date: 2019-01-15 17:56:00

categories: [spark,数据处理实践]

tags: [spark,todo]

---





<!--more-->

## kryo 介绍

详细文档可以查看官方文档 [wiki](https://github.com/EsotericSoftware/kryo)

这里简单做个摘要:

### kryo 应用实例

#### 序列化与反序列化

```java
import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.io.Input;
import com.esotericsoftware.kryo.io.Output;
import java.io.*;

public class HelloKryo {
   static public void main (String[] args) throws Exception {
      Kryo kryo = new Kryo();
      kryo.register(SomeClass.class);

      SomeClass object = new SomeClass();
      object.value = "Hello Kryo!";

      Output output = new Output(new FileOutputStream("file.bin"));
      kryo.writeObject(output, object);
      output.close();

      Input input = new Input(new FileInputStream("file.bin"));
      SomeClass object2 = kryo.readObject(input, SomeClass.class);
      input.close();   
   }
   static public class SomeClass {
      String value;
   }
}
```

#### 拷贝

```java
public class Test{
    Kryo kryo = new Kryo();
    SomeClass object = new SomeClass();
    // 深拷贝
    SomeClass copy1 = kryo.copy(object);
    // 浅拷贝
    SomeClass copy2 = kryo.copyShallow(object);
}
```

自定义 Serializer 的 copy方法生效的条件有两个。只要满足其中一个即可

- SomeClass 实现 `KryoCopyable<T>接口`
- 自定义 Serializer 重写 `Serializer<T>` 的copy方法

### 自带 Serializer

- addDefaultSerializer 仅仅说明对于某一种 type，应该使用 哪一个 serializer。 
- register方法，在执行内部 会显式指定 一个Id 用于 标识 这个 type+serializer 对。

```text
addDefaultSerializer(byte[].class, ByteArraySerializer.class);
addDefaultSerializer(char[].class, CharArraySerializer.class);
addDefaultSerializer(short[].class, ShortArraySerializer.class);
addDefaultSerializer(int[].class, IntArraySerializer.class);
addDefaultSerializer(long[].class, LongArraySerializer.class);
addDefaultSerializer(float[].class, FloatArraySerializer.class);
addDefaultSerializer(double[].class, DoubleArraySerializer.class);
addDefaultSerializer(boolean[].class, BooleanArraySerializer.class);
addDefaultSerializer(String[].class, StringArraySerializer.class);
addDefaultSerializer(Object[].class, ObjectArraySerializer.class);
addDefaultSerializer(KryoSerializable.class, KryoSerializableSerializer.class);
addDefaultSerializer(BigInteger.class, BigIntegerSerializer.class);
addDefaultSerializer(BigDecimal.class, BigDecimalSerializer.class);
addDefaultSerializer(Class.class, ClassSerializer.class);
addDefaultSerializer(Date.class, DateSerializer.class);
addDefaultSerializer(Enum.class, EnumSerializer.class);
addDefaultSerializer(EnumSet.class, EnumSetSerializer.class);
addDefaultSerializer(Currency.class, CurrencySerializer.class);
addDefaultSerializer(StringBuffer.class, StringBufferSerializer.class);
addDefaultSerializer(StringBuilder.class, StringBuilderSerializer.class);
addDefaultSerializer(Collections.EMPTY_LIST.getClass(), CollectionsEmptyListSerializer.class);
addDefaultSerializer(Collections.EMPTY_MAP.getClass(), CollectionsEmptyMapSerializer.class);
addDefaultSerializer(Collections.EMPTY_SET.getClass(), CollectionsEmptySetSerializer.class);
addDefaultSerializer(Collections.singletonList(null).getClass(), CollectionsSingletonListSerializer.class);
addDefaultSerializer(Collections.singletonMap(null, null).getClass(), CollectionsSingletonMapSerializer.class);
addDefaultSerializer(Collections.singleton(null).getClass(), CollectionsSingletonSetSerializer.class);
addDefaultSerializer(TreeSet.class, TreeSetSerializer.class);
addDefaultSerializer(Collection.class, CollectionSerializer.class);
addDefaultSerializer(TreeMap.class, TreeMapSerializer.class);
addDefaultSerializer(Map.class, MapSerializer.class);
addDefaultSerializer(TimeZone.class, TimeZoneSerializer.class);
addDefaultSerializer(Calendar.class, CalendarSerializer.class);
addDefaultSerializer(Locale.class, LocaleSerializer.class);
addDefaultSerializer(Charset.class, CharsetSerializer.class);
addDefaultSerializer(URL.class, URLSerializer.class);
addDefaultSerializer(Arrays.asList().getClass(), ArraysAsListSerializer.class);
addDefaultSerializer(void.class, new VoidSerializer());
addDefaultSerializer(PriorityQueue.class, new PriorityQueueSerializer());

register(int.class, new IntSerializer());
register(String.class, new StringSerializer());
register(float.class, new FloatSerializer());
register(boolean.class, new BooleanSerializer());
register(byte.class, new ByteSerializer());
register(char.class, new CharSerializer());
register(short.class, new ShortSerializer());
register(long.class, new LongSerializer());
register(double.class, new DoubleSerializer());
```

### 无匹配 Serializer 时
当 kryo 找不到 合适的 Serializer时，他会使用 FieldSerializer。当然这个默认的Serializer，是可以修改的。

```text
Kryo kryo = new Kryo();
kryo.setDefaultSerializer(TaggedFieldSerializer.class);
```

## 参考

[利用Kryo序列化库是你提升Spark性能要做的第一件事](https://www.jianshu.com/p/8ccd701490cf)
[什么时候使用kryo](https://stackoverflow.com/questions/40261987/when-to-use-kryo-serialization-in-spark)

