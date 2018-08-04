---
title: mock测试
date: 2018-06-04 23:22:58
tags: 
  - mock
categories:
  - springboot
---

```java
package zl.tenant.controller.impl;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@RunWith(SpringRunner.class)
@ActiveProfiles("zl")
@SpringBootTest(
        properties = {"frms.workflow.daemon.enable: false",
                "dev.debug: true",
                "frms.workflow.SchemaSearch: false"},
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
public class PlatformApiTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(username = "zl", password = "qqqq", authorities = {"TENANT_LIST"})
    public void platformTenantListGet() throws Exception {
        mockMvc.perform(
                MockMvcRequestBuilders.get("/rs/dm/platform/tenant/list")
                        .param("curPage", "1")
                        .param("pageSize", "20")
        ).andExpect(status().isOk())
                .andReturn();
    }
}
```



