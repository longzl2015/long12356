---

title: 协议-websocket

date: 2018-11-08 17:17:00

categories: [web,协议]

tags: [websocket,todo]

---





<!--more-->


## spring websocket 配置样例


```java
@Configuration
@EnableWebSocketMessageBroker //启用 websocket
public class WebSocketConfig extends AbstractWebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry
        .addEndpoint("/websocket")  // 配置 websocket 连接端点
        .withSockJS();              // 启用 sockJs 支持
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/rs/dm/topic"); // 设置 向客户端发送消息的前缀，不满足该前缀的目的地会被过滤掉。
    }
}
```

