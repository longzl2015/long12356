---

title: java安全简单入门

date: 2019-08-10 15:46:00

categories: [语言,java]

tags: [java]

---



Policy文件、安全管理器 SecurityManager、存取控制器AccessController



## Policy文件

Policy文件 默认位于 `$JAVA_HOME/jre/lib/security/java.policy`。

可通过 `-Djava.security.policy="E:/java.policy"` 指定 Policy文件位置。

默认Policy文件(在开启安全策略的情况下):

- 允许标准扩展包拥有所有权限
- 其他域，允许 各种java属性的 read 权限
- 其他操作 如读文件、写文件等等都是禁止的

```
// Standard extensions get all permissions by default
grant codeBase "file:${{java.ext.dirs}}/*" {
        permission java.security.AllPermission;
};

// default permissions granted to all domains
grant {
        // Allows any thread to stop itself using the java.lang.Thread.stop()
        // method that takes no argument.
        // Note that this permission is granted by default only to remain
        // backwards compatible.
        // It is strongly recommended that you either remove this permission
        // from this policy file or further restrict it to code sources
        // that you specify, because Thread.stop() is potentially unsafe.
        // See the API specification of java.lang.Thread.stop() for more
        // information.
        permission java.lang.RuntimePermission "stopThread";

        // allows anyone to listen on dynamic ports
        permission java.net.SocketPermission "localhost:0", "listen";

        // "standard" properies that can be read by anyone

        permission java.util.PropertyPermission "java.version", "read";
        permission java.util.PropertyPermission "java.vendor", "read";
        permission java.util.PropertyPermission "java.vendor.url", "read";
        permission java.util.PropertyPermission "java.class.version", "read";
        permission java.util.PropertyPermission "os.name", "read";
        permission java.util.PropertyPermission "os.version", "read";
        permission java.util.PropertyPermission "os.arch", "read";
        permission java.util.PropertyPermission "file.separator", "read";
        permission java.util.PropertyPermission "path.separator", "read";
        permission java.util.PropertyPermission "line.separator", "read";

        permission java.util.PropertyPermission "java.specification.version", "read";
        permission java.util.PropertyPermission "java.specification.vendor", "read";
        permission java.util.PropertyPermission "java.specification.name", "read";

        permission java.util.PropertyPermission "java.vm.specification.version", "read";
        permission java.util.PropertyPermission "java.vm.specification.vendor", "read";
        permission java.util.PropertyPermission "java.vm.specification.name", "read";
        permission java.util.PropertyPermission "java.vm.version", "read";
        permission java.util.PropertyPermission "java.vm.vendor", "read";
        permission java.util.PropertyPermission "java.vm.name", "read";
};
```

##SecurityManager

SecurityManager 为其他API提供各种check接口，检查当期操作是否被允许。

开启 SecurityManager 有两种方式:

- 命令行添加 `-Djava.security.manager`
- 代码中添加 `System.setSecurityManager(new SecurityManager());`

check接口例子:

```
checkCreateClassLoader 检查是否有创建classloader的权限
checkDelete            检查是否有删除指定文件的权限
checkExec              检查是否有文件执行的权限
checkExit              检查是否有exitVM的权限
等等
```

##AccessController

AccessController的构造器私有，它对外提供一些静态方法:

- checkPermission(Permission p) 检查代码是否有权限
- AccessController.doPrivileged 还没研究透。

## 优质文章

[Java安全：SecurityManager与AccessController](https://juejin.im/post/5b693511e51d45195113866a)

[Java安全——理解Java沙箱](https://www.zybuluo.com/changedi/note/237999)

[AccessController.doPrivileged](https://blog.csdn.net/teamlet/article/details/1809165)