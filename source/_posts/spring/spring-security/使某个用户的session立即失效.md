---

title: 使某个用户的session立即失效(转)

date: 2019-06-10 11:09:08

categories: [spring,springsecurity]

tags: [SpringSecurity]

---

当修改用户的相关权限后，每次都需要客户手动重新登录，这样的实现方式一点也不优美。本篇转载了《Spring - Expiring all Sessions of a User》

<!--more-->

Recently, I faced a problem where I had to expire all sessions of a user in Spring MVC. There are answered stackoverflow questions but either they were answered in xml config or they did not cover all aspects. Here is how I managed to do it:

## 配置SecurityConfig

Following class is the configuration class and I’ll explain it step by step:

```java

@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.sessionManagement()
        	.maximumSessions(100)               //(1)
        	.maxSessionsPreventsLogin(false)    //(2)
        	.expiredUrl("/auth/login")          //(3)
        	.sessionRegistry(sessionRegistry()) //(4)
        ;
    }
    @Bean
    SessionRegistry sessionRegistry() {			
        return new SessionRegistryImpl();
    }
    @Bean
    public static ServletListenerRegistrationBean httpSessionEventPublisher() {	//(5)
        return new ServletListenerRegistrationBean(new HttpSessionEventPublisher());
    }
}
```

### ConcurrencyControlConfigurer
To register SessionRegistry bean, we need ConcurrencyControlConfigurer which is only provided by http
.sessionManagement().maximumSessions(int) call. That’s why I specified it to be a large number, because I don’t want to limit users.

### Prevent login
I had to limit maximum session count but I don’t want to prevent a user from logging in. Here is the javadoc:

> If true, prevents a user from authenticating when the SessionManagementConfigurer.maximumSessions(int) has been reached. Otherwise (default), the 
user who authenticates is allowed access and an existing user’s session is expired. The user’s who’s session is forcibly expired is sent to expiredUrl(String). The advantage of this approach is if a user accidentally does not log out, there is no need for an administrator to intervene or wait till their session expires.

### Expired url
When user sessions are expired successfully, user was facing this simple text when re-logging in:

> This session has been expired (possibly due to multiple concurrent logins being attempted as the same user).

Instead, I specified the redirection url by this config. Users go to login page when I kill their session in server.

### Session Registry
SessionRegistry bean is necessary to reach sessions stored on server.

### HttpSessionEventPublisher
To tell Spring to store sessions in the registry, we need HttpSessionEventPublisher bean.

The configuration is completed. Now Spring stores every session in SessionRegistry. We can traverse the registered sessions to retrive session information of all authenticated users at that moment. Here is a utility class to find and expire user sessions:

## 使用

```java
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.session.SessionInformation;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;
@Component
public class SessionUtils {
    @Autowired
    private SessionRegistry sessionRegistry;
    public void expireUserSessions(String username) {
        for (Object principal : sessionRegistry.getAllPrincipals()) {
            if (principal instanceof User) {
                UserDetails userDetails = (UserDetails) principal;
                if (userDetails.getUsername().equals(username)) {
                    for (SessionInformation information : sessionRegistry.getAllSessions(userDetails, true)) {
                        information.expireNow();
                    }
                }
            }
        }
    }
}
```

After calling this method, all of user sessions are expired and when user makes a new request, she will be processed through logout steps. Because we registered concurrent session configuration above, ConcurrentSessionFilter is inserted by Spring and following code segment runs for every request:

```java

if (session != null) {
    SessionInformation info = sessionRegistry.getSessionInformation(session.getId());
    if (info != null) {
        if (info.isExpired()) {
            // Expired - abort processing
            doLogout(request, response);		//!!!!
            String targetUrl = determineExpiredUrl(request, info);
            if (targetUrl != null) {
                redirectStrategy.sendRedirect(request, response, targetUrl);
                return;
            } else {
                response.getWriter().print("This session has been expired (possibly due to multiple concurrent " +
                        "logins being attempted as the same user).");
                response.flushBuffer();
            }
            return;
        } else {
            // Non-expired - update last request date/time
            sessionRegistry.refreshLastRequest(info.getSessionId());
        }
    }
}
```

See the line with exclamation points? That’s where Spring decides that session is expired and logs out user.

I tried this in a handler where I wanted to expire all user sessions and redirect requesting session to some other page with flash attributes. 
All sessions are expired as expected, but the request is not redirected with flash attributes as I intended because of logout logic, remember that.

## 来源
https://mtyurt.net/post/spring-expiring-all-sessions-of-a-user.html
