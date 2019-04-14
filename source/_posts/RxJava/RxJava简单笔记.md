---

title: RxJava简单笔记

date: 2019-04-08 10:44:00

categories: [RxJava]

tags: [RxJava]

---


本章用于 记录自己学习 RxJava 的简单笔记


<!--more-->

下面的 代码 主要做的是 将 整型 `100` 转成 字符串 `100`，并打印。

```java
class Demo{
    private void funcDemo() {
        
        // Invoked when Observable.subscribe is called
        Observable.OnSubscribe onSubscribe1 = new Observable.OnSubscribe() {
            // 为 观察者 提供 一个新的待观察的 item
            // 在该实例中为 提供 一个 整型 100  
            @Override
            public void call(Subscriber subscriber) {
                subscriber.onNext(100);
            }
        };
        
        // 观察回调
        // 本实例中为 将整型转为 字符串型
        Func1 func1 = new Func1() {
            @Override
            public String call(Integer integer) {
                return String.valueOf(integer);
            }
        };
    
        // 观察者，接收来自 被观察者的通知
        Subscriber subscriber1 = new Subscriber() {
            // 通知观察者: 被观察对象已完成工作 
            // 若 被观察者 调用了 onError(),则 onCompleted 不会被调用
            @Override
            public void onCompleted() {
            }
            // 通知观察者: 被观察对象 运行过程中，出现了错误 
            @Override
            public void onError(Throwable e) {
            }
    
            // 通知观察者: 准备 接收下一个 待观察对象
            // 该方法可以调用多次。
            // 若调用过 onCompleted() 和 onError()，onNext 就不会被调用了。
            @Override
            public void onNext(String s) {
                Log.d("onNext(): ", s);
            }
        };
    
        Observable.create(onSubscribe1)
                .map(func1)
                .subscribe(subscriber1);
    }
}
```

## 参考

[RxJava 的使用与理解（一）](https://juejin.im/entry/57049996128fe10052514a81)
[RxJava操作符-辅助操作符](https://blog.csdn.net/qq_20198405/article/details/51307198)