---
title: log监控
tags: 
  - log监控
categories:
  - springboot
---

```java
package zl.dm.dev.logweb;

import zl.dm.exception.InvalidRequestParamException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;


/**
 * modelBuild/logview.html
 *
 * @author zhoulong
 */
public class LogWebSocketHandler extends TextWebSocketHandler {
    private static final Logger log = LoggerFactory.getLogger(LogWebSocketHandler.class);
    @Value("${dev.log.path:./log/dm.log}")
    String logFile;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        log.info("current webSocket:{} has connected", session.getId());
    }

    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        log.info("current webSocket:{} has handleTextMessage", session.getId());
        String payload = message.getPayload();
        Long sizeOff = Long.parseLong(payload);
        getLogLine(sizeOff, session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        session.close();
        log.info("current webSocket:{} has disconnected", session.getId());
    }


    private void getLogLine(Long sizeOff, WebSocketSession session) throws InterruptedException {
        File file = new File(logFile);
        RandomAccessFile randomAccessFile;
        try {
            randomAccessFile = new RandomAccessFile(file, "r");

            // 初始化信息
            long fileSize = randomAccessFile.length();
            session.sendMessage(new TextMessage("============日志文件当前总大小为" + fileSize + "============</br>"));

            if (sizeOff < 0) {
                sizeOff = fileSize + sizeOff;
            }
            session.sendMessage(new TextMessage("============日志文件当前偏移量为" + sizeOff + "============</br></br></br>"));
            randomAccessFile.seek(sizeOff);
            String tmpLine;
            StringBuffer lines = new StringBuffer();
            int count = 0;
            boolean reachBottom = `false`;

            //发送信息
            while (session.isOpen()) {
                tmpLine = randomAccessFile.readLine();

                if (tmpLine == null) {
                    Thread.sleep(1000);
                } else {
                    reachBottom = (randomAccessFile.length() - randomAccessFile.getFilePointer()) < 1000;
                    lines.append(new String(tmpLine.getBytes("ISO-8859-1"), "utf-8")).append("</br>");

                    if (!reachBottom) {
                        if (count >= 3000) {
                            session.sendMessage(new TextMessage(lines));
                            count = 0;
                            lines.setLength(0);
                            Thread.sleep(500);
                        } else {
                            count++;
                        }
                    } else {
                        session.sendMessage(new TextMessage(lines));
                        count = 0;
                        lines.setLength(0);
                        Thread.sleep(100);
                    }
                }
            }
            log.info("断开 logview 连接");
        } catch (FileNotFoundException e) {
            throw new InvalidRequestParamException("找不到日志文件，路径{}", file.getAbsolutePath());
        } catch (IOException e) {
            throw new InvalidRequestParamException(e.getMessage(), e.getMessage(), e);
        }
    }


}


```

```java
package zl.dm.conf;

import zl.dm.dev.logweb.LogWebSocketHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.*;

/**
 * @author zhoulong
 */
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {


    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry webSocketHandlerRegistry) {
        webSocketHandlerRegistry.addHandler(logWebSocketHandler(), "/websocket").withSockJS();
    }

    @Bean
    public LogWebSocketHandler logWebSocketHandler() {
        return new LogWebSocketHandler();
    }
}

```

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8"/>
    <title>日志预览</title>
</head>
<body>
<noscript><h2 style="color: #ff0000">貌似你的浏览器不支持websocket</h2></noscript>

<div>
    <button id="connect" onclick="connect()">连接socket</button>
    <button id="disconnect" onclick="disconnect()" disabled="disabled">断开</button>
</div>

<br>
<div id="conversationDiv" style="display:none">
    <label>输入字节偏移量</label><input type="text" id="size_off" value="-5000"/>
    <button id="send" onclick="send()">查看日志</button>
</div>

<br>
<div id="log-container">
    <div></div>
</div>
<div id="end">

</div>

<script src="./app/assets/js/lib/jquery/dist/jquery.min.js"></script>
<script src="./app/assets/js/lib/sockjs.min.js"></script>
<script src="./app/assets/js/lib/stomp.min.js"></script>

<script type="text/javascript">
    var ws = null;
    var sendFlag = false;

    function connect() {
        ws = new SockJS("/websocket");
        ws.onopen = function () {
            document.getElementById('connect').disabled = true;
            document.getElementById('disconnect').disabled = false;
            $("#conversationDiv").show();
        };
        ws.onmessage = function (event) {
            $("#log-container div").append(event.data);
            // $("#log-container").scrollTop($("#log-container div").height() - $("#log-container").height());
            var div = document.getElementById('end');
            div.scrollIntoView();
        };
        ws.onclose = function () {
            document.getElementById('connect').disabled = false;
            document.getElementById('disconnect').disabled = true;
            $("#conversationDiv").hide();
            sendFlag = false;
        };
    }

    function disconnect() {
        if (ws != null) {
            ws.close();
            ws = null;
        }
    }

    function send() {
        var size_off = $('#size_off').val();
        if (size_off > -1000 && size_off < 0) {
            alert("size_off为负数，则必须小于 -1000");
            return;
        }

        if (ws != null && !sendFlag) {
            $("#log-container div").empty()
            ws.send(size_off);
            sendFlag = true;
        } else if (sendFlag) {
            alert('第二次查看日志时，需要重新连接socket')
        } else {
            alert('连接尚未建立，请先连接 webSock');
        }
    }

</script>
</body>
</html>
```

