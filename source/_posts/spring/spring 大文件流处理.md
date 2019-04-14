---

title: spring 大文件流处理

date: 2019-04-14 20:23:00

categories: [spring,流处理]

tags: [spring,流处理]

---

StreamingResponseBody

<!--more-->


## controller 以流的形式 返回数据

实现以流的形式返回数据，可以使用 `StreamingResponseBody`。样例如下:

```java
@Controller
public class TestController2 {

    @RequestMapping("/test")
    public ResponseEntity<StreamingResponseBody> handleRequest () {

        StreamingResponseBody responseBody = new StreamingResponseBody() {
            @Override
            public void writeTo (OutputStream out) throws IOException {
                for (int i = 0; i < 1000; i++) {
                    out.write(
                            (Integer.toString(i) + " - ").getBytes()
                                       );
                    out.flush();
                }
            }
        };

        return new ResponseEntity(responseBody, HttpStatus.OK);
    }
}
```

使用 ResponseEntity 的原因是 可以 添加各种响应头的状态码。


## controller 以流的形式 接收数据

由于 MultipartResolver 会将浏览器传送来的流数据读取掉后保存到临时目录，这会造成流不可用。因此我们需要禁用这个功能。

```yaml
spring.servlet.multipart.enabled: false
```

接着是controller 如何读取流信息。

```java
@RestController
public class FileUploadController {
    @RequestMapping(value="/upload", method=RequestMethod.POST)
    public void upload(HttpServletRequest request) {
        try {
            boolean isMultipart = ServletFileUpload.isMultipartContent(request);
            if (!isMultipart) {
                // Inform user about invalid request
                Response<String> responseObject = new Response<String>(false, "Not a multipart request.", "");
                return responseObject;
            }

            // Create a new file upload handler
            ServletFileUpload upload = new ServletFileUpload();

            // Parse the request
            FileItemIterator iter = upload.getItemIterator(request);
            while (iter.hasNext()) {
                FileItemStream item = iter.next();
                String name = item.getFieldName();
                InputStream stream = item.openStream();
                if (!item.isFormField()) {
                    String filename = item.getName();
                    // Process the input stream
                    OutputStream out = new FileOutputStream(filename);
                    IOUtils.copy(stream, out);
                    stream.close();
                    out.close();
                }
            }
        } catch (FileUploadException e) {
            return new Response<String>(false, "File upload error", e.toString());
        } catch (IOException e) {
            return new Response<String>(false, "Internal server IO error", e.toString());
        }
    }
}
```


## 参考
[ApacheCommonsFileUpload-streaming](http://commons.apache.org/proper/commons-fileupload/streaming.html)
[Stack Overflow 大文件流处理](https://stackoverflow.com/questions/32782026/springboot-large-streaming-file-upload-using-apache-commons-fileupload)