---
title: kerberos 介绍
date: 2019-06-02 22:46:48
tags: 
  - kerberos
categories: [hadoop生态,kerberos]
---



## 使用java代码 获取 TGT 

```java
public void login(Configuration conf) throws IOException {       
  System.setProperty("java.security.krb5.conf", "krb5配置文件路径");
  UserGroupInformation.setConfiguration(conf);
  UserGroupInformation.loginUserFromKeytab(PRNCIPAL_NAME, PATH_TO_KEYTAB);        
}
```

```java
/*
* 通过java.security.krb5.conf       获取 krb.conf
* 通过hadoop.security.auth_to_local 设置 principal 映射规则
*/
public static void setConfiguration(Configuration conf) {
  initialize(conf, true);
}
private static synchronized void initialize(Configuration conf,
                                              boolean overrideNameRules) {
  // 根据 hadoop.security.authentication 判断 hadoop 的认证方法
  authenticationMethod = SecurityUtil.getAuthenticationMethod(conf);
  if (overrideNameRules || !HadoopKerberosName.hasRulesBeenSet()) {
    try {
// (以非IBM jdk为例)
// 1. 通过反射实例化 sun.security.krb5.Config: 在本例中Config的实例化信息 来自 java.security.krb5.conf 指定的krb5.conf配置文件
// 2. 读取 hadoop.security.auth_to_local，并设置principal映射规则
      HadoopKerberosName.setConfiguration(conf);
    } catch (IOException ioe) {
      throw new RuntimeException(
        "Problem with Kerberos auth_to_local name configuration", ioe);
    }
  }
  // metrics 和 groups 
  if (!(groups instanceof TestingGroups)) {
    groups = Groups.getUserToGroupsMappingService(conf);
  }
  UserGroupInformation.conf = conf;
  if (metrics.getGroupsQuantiles == null) {
    int[] intervals = conf.getInts(HADOOP_USER_GROUP_METRICS_PERCENTILES_INTERVALS);
    if (intervals != null && intervals.length > 0) {
      final int length = intervals.length;
      MutableQuantiles[] getGroupsQuantiles = new MutableQuantiles[length];
      for (int i = 0; i < length; i++) {
        getGroupsQuantiles[i] = metrics.registry.newQuantiles(
          "getGroups" + intervals[i] + "s",
          "Get groups", "ops", "latency", intervals[i]);
      }
      metrics.getGroupsQuantiles = getGroupsQuantiles;
    }
  }
}
```

```java
public synchronized
  static void loginUserFromKeytab(String user,
                                  String path
                                  ) throws IOException {
    if (!isSecurityEnabled())
      return;

    keytabFile = path;
    keytabPrincipal = user;
    Subject subject = new Subject();
    LoginContext login; 
    long start = 0;
    try {
      // 
      login = newLoginContext(HadoopConfiguration.KEYTAB_KERBEROS_CONFIG_NAME,
            subject, new HadoopConfiguration());
      start = Time.now();
      // Krb5LoginModule
      // HadoopLoginModule
      login.login();
      metrics.loginSuccess.add(Time.now() - start);
      loginUser = new UserGroupInformation(subject);
      loginUser.setLogin(login);
      loginUser.setAuthenticationMethod(AuthenticationMethod.KERBEROS);
    } catch (LoginException le) {
      if (start > 0) {
        metrics.loginFailure.add(Time.now() - start);
      }
      throw new IOException("Login failure for " + user + " from keytab " + 
                            path+ ": " + le, le);
    }
    LOG.info("Login successful for user " + keytabPrincipal
        + " using keytab file " + keytabFile);
  }
```

Krb5LoginModule 中几个重要的方法:

- attemptAuthentication()
- login()
- commit()

HadoopLoginModule中几个重要的方法:

- login()
- commit()



## 文章收集

UserGroupInformation.doAs

https://blog.csdn.net/weixin_35852328/article/details/83620379

Hadoop安全认证(2)

https://blog.csdn.net/daiyutage/article/details/52091779

Should I call ugi.checkTGTAndReloginFromKeytab() before every action on hadoop?

https://stackoverflow.com/questions/34616676/should-i-call-ugi-checktgtandreloginfromkeytab-before-every-action-on-hadoop



MIT 官方文档

[http://web.mit.edu/Kerberos/krb5-devel/doc/admin/index.html](http://web.mit.edu/Kerberos/krb5-devel/doc/admin/index.html)