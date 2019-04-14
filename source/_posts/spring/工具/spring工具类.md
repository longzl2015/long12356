---

title: spring工具类

date: 2018-11-22 11:28:00

categories: [springboot,spring工具类]

tags: [工具类]

---


spring 工具类笔记


<!--more-->

## WebUtils

### 常用

| 方法                        | 作用                         |
|-----------------------------|------------------------------|
| findParameterValue          | 获取request中指定的parameter |
| getCookie                   | 获取request中指定的cookie    |
| getSessionAttribute         | 获取 SessionAttribute        |
| getRequiredSessionAttribute | 获取 SessionAttribute        |
| getSessionId                | 获取 会话Id                  |
| setSessionAttribute         | 设置会话属性                 |
| isSameOrigin                | 是否同源                     |
| isValidOrigin               | 是否有效Origin               |

### 其他

| 方法                           | 作用                                                                                                      |
|--------------------------------|-----------------------------------------------------------------------------------------------------------|
| clearErrorRequestAttributes    | 清除servlet特定的error_attributes                                                                         |
| exposeErrorRequestAttributes   | 将错误信息设置到servlet的error_attributes                                                                 |
| getDefaultHtmlEscape           | 获取是否启用转义配置                                                                                      |
| getNativeRequest               | 进行类型转换                                                                                              |
| getNativeResponse              | 进行类型转换                                                                                              |
| getParametersStartingWith      | 获取指定前缀的parameter                                                                                   |
| getRealPath                    | 获取真实路径                                                                                              |
| getResponseEncodedHtmlEscape   | 获取是否启用转义配置                                                                                      |
| getSessionMutex                | [会话互斥](https://stackoverflow.com/questions/9802165/is-synchronization-within-an-httpsession-feasible) |
| getTempDir                     | 获取当前web应用的临时目录                                                                                 |
| hasSubmitParameter             | 检查 是否是 input type ='submit'的请求                                                                    |
| isIncludeRequest               |                                                                                                           |
| parseMatrixVariables           |                                                                                                           |
| removeWebAppRootSystemProperty |                                                                                                           |
| setWebAppRootSystemProperty    |                                                                                                           |


## RequestContextHolder

