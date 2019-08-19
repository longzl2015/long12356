---
title: spring-6-HandlerMethodArgumentResolver参数解析器
date: 2019-06-09 11:09:06
tags: 
  - springmvc
categories: [spring,springmvc]

---

# HandlerMethodArgumentResolver参数解析器

前文《spring-6-controller参数解析原理》介绍了 Controller 的整体参数解析原理。

本文章主要介绍集中介绍 HandlerMethodArgumentResolver在SpringMVC中的使用，介绍几个HandlerMethodArgumentResolver具体的使用情况，然后说明HandlerMethodArgumentResolver的注册来源以及如何自定义注册。

## 一、类图

![springmvc_handlerMethod](/images/spring-6-HandlerMethodArgumentResolver参数解析器/springmvc_handlerMethod.png)

## 二、HandlerMethodArgumentResolver 及其子类 

### 2.1 HandlerMethodArgumentResolver

HandlerMethodArgumentResolver接口只有两个方法：

```java
public interface HandlerMethodArgumentResolver {
    boolean supportsParameter(MethodParameter var1);

    Object resolveArgument(MethodParameter var1, ModelAndViewContainer var2, NativeWebRequest var3, WebDataBinderFactory var4) throws Exception;
}
```

### 2.2  AbstractMessageConverterMethodArgumentResolver 

HandlerMethodArgumentResolver接口的抽象类： 仅仅引入了HttpMessageConverter，即具体的转换工作由这些HttpMessageConverter来完成。 

```java
public abstract class AbstractMessageConverterMethodArgumentResolver implements HandlerMethodArgumentResolver {

	private static final Set<HttpMethod> SUPPORTED_METHODS =
			EnumSet.of(HttpMethod.POST, HttpMethod.PUT, HttpMethod.PATCH);

	private static final Object NO_VALUE = new Object();

	protected final Log logger = LogFactory.getLog(getClass());

	protected final List<HttpMessageConverter<?>> messageConverters;

	protected final List<MediaType> allSupportedMediaTypes;

	private final RequestResponseBodyAdviceChain advice;
//略
}
```

### 2.3 AbstractMessageConverterMethodProcessor

AbstractMessageConverterMethodArgumentResolver 的抽象子类，加入了对响应数据进行转换的支持。 
使其不仅可以用来转换请求数据，也可以用来转换响应数据。 

下面简单介绍AbstractMessageConverterMethodProcessor 的子类：HttpEntityMethodProcessor和RequestResponseBodyMethodProcessor

#### 2.3.1 HttpEntityMethodProcessor

AbstractMessageConverterMethodProcessor的子类，支持请求和响应的转换

```java
public class HttpEntityMethodProcessor extends AbstractMessageConverterMethodProcessor {
	@Override
	public boolean supportsParameter(MethodParameter parameter) {
		return (HttpEntity.class == parameter.getParameterType() ||
				RequestEntity.class == parameter.getParameterType());
	}

	@Override
	public boolean supportsReturnType(MethodParameter returnType) {
		return (HttpEntity.class.isAssignableFrom(returnType.getParameterType()) &&
				!RequestEntity.class.isAssignableFrom(returnType.getParameterType()));
	}
}
```

使用场景：

```java
public class Test{
    @RequestMapping(value="/test/http",method=RequestMethod.POST)  
    @ResponseBody  
    public Map<String,Object> testHttp(HttpEntity<String> httpEntity){
       //略   
    }  
    @RequestMapping(value="/test/httpEntity",method=RequestMethod.GET)  
    public HttpEntity<String> testHttpEntity(){  
       //略  
    } 
}
```

#### 2.3.2 RequestResponseBodyMethodProcessor

AbstractMessageConverterMethodProcessor 的子类：支持`@RequestBody`和`@ResponseBody`

```java
public class RequestResponseBodyMethodProcessor extends AbstractMessageConverterMethodProcessor {
    @Override 
    public boolean supportsParameter(MethodParameter parameter) { 
       //查找参数中是否含有@RequestBody注解 
       return parameter.hasParameterAnnotation(RequestBody.class); 
    } 
    @Override 
    public boolean supportsReturnType(MethodParameter returnType) { 
    //查找参数中是否含有@RequestBody注解或者controller类上是否含有@RequestBody 
    return ((AnnotationUtils.findAnnotation(returnType.getContainingClass(), ResponseBody.class) != null) || 
    (returnType.getMethodAnnotation(ResponseBody.class) != null)); 
    } 
}
```

使用场景如下：

```java
public class Test{
    @RequestMapping(value="/test/requestBody",method=RequestMethod.POST)  
    @ResponseBody  
    public Map<String,Object> testrequestBody(@RequestBody Map<String,Object> map1){  
       Map<String,Object> map=new HashMap<String,Object>();  
       map.put("name","lg");  
       map.put("age",23);  
       map.put("date",new Date());  
       return map;  
    }
}
```

#### 2.3.3 HttpEntityMethodProcessor 解析过程：

通过 HttpMessageConverter 来进一步的判断是否支持`HttpEntity<T>`中我们想要的T类型以及是否支持相应的content-type，如`public Map<String,Object> testHttp(HttpEntity<String> httpEntity)` ，则会选择StringHttpMessageConverter来进行转换。具体的选择过程如下：

```java

@Override  
public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,  NativeWebRequest webRequest, WebDataBinderFactory binderFactory)  
         throws IOException, HttpMediaTypeNotSupportedException {  
	HttpInputMessage inputMessage = createInputMessage(webRequest);  
    Type paramType = getHttpEntityType(parameter);  

    Object body = readWithMessageConverters(webRequest, parameter, paramType);  
    return new HttpEntity<Object>(body, inputMessage.getHeaders());  
}  

```

```java
protected <T> Object readWithMessageConverters(HttpInputMessage inputMessage,  
            MethodParameter methodParam, Type targetType) throws IOException, HttpMediaTypeNotSupportedException {  
	MediaType contentType;  
    try {  
       contentType = inputMessage.getHeaders().getContentType();  
    }catch (InvalidMediaTypeException ex) {  
       throw new HttpMediaTypeNotSupportedException(ex.getMessage());  
    }  
    if (contentType == null) {  
       contentType = MediaType.APPLICATION_OCTET_STREAM;  
    }  
    Class<?> contextClass = methodParam.getContainingClass();  
    for (HttpMessageConverter<?> converter : this.messageConverters) {  
       if (converter instanceof GenericHttpMessageConverter) {  
           GenericHttpMessageConverter<?> genericConverter = (GenericHttpMessageConverter<?>) converter;  
       if (genericConverter.canRead(targetType, contextClass, contentType)) {  
           if (logger.isDebugEnabled()) {  
               logger.debug("Reading [" + targetType + "] as \"" +  
                        contentType + "\" using [" + converter + "]");  
           }  
           return genericConverter.read(targetType, contextClass, inputMessage);  
       }  
    }  
    Class<T> targetClass = (Class<T>) ResolvableType.forMethodParameter(methodParam, targetType).resolve(Object.class);  
    
    if (converter.canRead(targetClass, contentType)) {  
       if (logger.isDebugEnabled()) {  
          logger.debug("Reading [" + targetClass.getName() + "] as \"" +  
                          contentType + "\" using [" + converter + "]");                           
          return ((HttpMessageConverter<T>) converter).read(targetClass, inputMessage);  
       }  
    }  
    
    throw new HttpMediaTypeNotSupportedException(contentType, this.allSupportedMediaTypes);  
}  
```

#### 2.3.4RequestResponseBodyMethodProcessor解析过程 

RequestResponseBodyMethodProcessor也会使用相应的HttpMessageConverter来进行转换。如`public Map<String,Object> testrequestBody(@RequestBody Map<String,Object> map1)`则会选择MappingJackson2HttpMessageConverter或者MappingJacksonHttpMessageConverter来完成转换。 

### 2.4 AbstractNamedValueMethodArgumentResolver 

该类主要用于解析方法入参，他有多个子类，这里简单介绍其中四种类型

#### 2.4.1 RequestParamMethodArgumentResolver 

RequestParamMethodArgumentResolver支持的类型有，一种是含@RequestParam注解的参数，另一种就是简单类型，如Integer、String、Date、URI、URL、Locale等： 

```java
public boolean supportsParameter(MethodParameter parameter) {  
        Class<?> paramType = parameter.getParameterType();  
        if (parameter.hasParameterAnnotation(RequestParam.class)) {  
            if (Map.class.isAssignableFrom(paramType)) {  
                String paramName = parameter.getParameterAnnotation(RequestParam.class).value();  
                return StringUtils.hasText(paramName);  
            }  
            else {  
                return true;  
            }  
        }  
        else {  
            if (parameter.hasParameterAnnotation(RequestPart.class)) {  
                return false;  
            }  
            else if (MultipartFile.class.equals(paramType) || "javax.servlet.http.Part".equals(paramType.getName())) {  
                return true;  
            }  
            else if (this.useDefaultResolution) {  
                return BeanUtils.isSimpleProperty(paramType);  
            }  
            else {  
                return false;  
            }  
        }  
    }  

```

BeanUtils.isSimpleProperty(paramType)判断是否是简单类型的具体内容如下：

```java
	public static boolean isSimpleProperty(Class<?> clazz) {
		Assert.notNull(clazz, "Class must not be null");
		return isSimpleValueType(clazz) || (clazz.isArray() && isSimpleValueType(clazz.getComponentType()));
	}

	public static boolean isSimpleValueType(Class<?> clazz) {
		return (ClassUtils.isPrimitiveOrWrapper(clazz) || clazz.isEnum() ||
				CharSequence.class.isAssignableFrom(clazz) ||
				Number.class.isAssignableFrom(clazz) ||
				Date.class.isAssignableFrom(clazz) ||
				URI.class == clazz || URL.class == clazz ||
				Locale.class == clazz || Class.class == clazz);
	}

```

即当请求为 http://localhost:8080/test?name=abc时，处理函数若为test(String name)，则对name的解析就是采用RequestParamMethodArgumentResolver来解析的。 

#### 2.4.2 RequestHeaderMethodArgumentResolver 

主要用来处理含有@RequestHeader注解的参数，但同时该参数又不是Map类型。如下：

```java
@Override  
public boolean supportsParameter(MethodParameter parameter) {  
     return parameter.hasParameterAnnotation(RequestHeader.class)  
           && !Map.class.isAssignableFrom(parameter.getParameterType());  
}  
 
@Override  
protected Object resolveName(String name, MethodParameter parameter, NativeWebRequest request) throws Exception {  
     String[] headerValues = request.getHeaderValues(name);  
     if (headerValues != null) {  
          return (headerValues.length == 1 ? headerValues[0] : headerValues);  
     }  
     else {  
          return null;  
     }  
}  


```

使用场景：

```java
	@RequestMapping(value="/test/requestHeader",method=RequestMethod.GET)  
    @ResponseBody  
    public Map<String,Object> testrequestHeader(@RequestHeader String  Accept){  
    ...
    }

```

#### 2.4.3RequestHeaderMapMethodArgumentResolver 

用来获取所有的header信息：

```java
public class RequestHeaderMapMethodArgumentResolver implements HandlerMethodArgumentResolver {

//这里已经写明白了，要求参数必须含有@RequestHeader注解，并且是Map类型
	@Override
	public boolean supportsParameter(MethodParameter parameter) {
		return parameter.hasParameterAnnotation(RequestHeader.class)
				&& Map.class.isAssignableFrom(parameter.getParameterType());
	}

	@Override
	public Object resolveArgument(
			MethodParameter parameter, ModelAndViewContainer mavContainer,
			NativeWebRequest webRequest, WebDataBinderFactory binderFactory)
			throws Exception {

		Class<?> paramType = parameter.getParameterType();

		if (MultiValueMap.class.isAssignableFrom(paramType)) {
			MultiValueMap<String, String> result;
			if (HttpHeaders.class.isAssignableFrom(paramType)) {
				result = new HttpHeaders();
			}
			else {
				result = new LinkedMultiValueMap<String, String>();
			}
			for (Iterator<String> iterator = webRequest.getHeaderNames(); iterator.hasNext();) {
				String headerName = iterator.next();
				for (String headerValue : webRequest.getHeaderValues(headerName)) {
					result.add(headerName, headerValue);
				}
			}
			return result;
		}
		else {
			Map<String, String> result = new LinkedHashMap<String, String>();
			for (Iterator<String> iterator = webRequest.getHeaderNames(); iterator.hasNext();) {
				String headerName = iterator.next();
				String headerValue = webRequest.getHeader(headerName);
				result.put(headerName, headerValue);
			}
			return result;
		}
	}
}


```

从上面的解析过程可以看出，参数类型可以是普通的Map类型，也可以是MultiValueMap或者进一步的HttpHeaders，他们与普通Map类型的区别是他们对value值后者们是以List形式存放，前者是以String形式存放。 

使用场景：

```java
@RequestMapping(value="/test/requestHeader",method=RequestMethod.GET)  
@ResponseBody  
public Map<String,Object> testrequestHeader(@RequestHeader Map<String,Object> map1){  
}  
  
public Map<String,Object> testrequestHeader(@RequestHeader MultiValueMap<String,Object> map1){
}

```

#### 2.4.4 PathVariableMethodArgumentResolver

主要针对含有@PathVariable的参数，代码如下：

```java
@Override
	public boolean supportsParameter(MethodParameter parameter) {
		if (!parameter.hasParameterAnnotation(PathVariable.class)) {
			return false;
		}
		if (Map.class.isAssignableFrom(parameter.getParameterType())) {
			String paramName = parameter.getParameterAnnotation(PathVariable.class).value();
			return StringUtils.hasText(paramName);
		}
		return true;
	}

@Override
	@SuppressWarnings("unchecked")
	protected Object resolveName(String name, MethodParameter parameter, NativeWebRequest request) throws Exception {
		Map<String, String> uriTemplateVars =
			(Map<String, String>) request.getAttribute(
					HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE, RequestAttributes.SCOPE_REQUEST);
		return (uriTemplateVars != null) ? uriTemplateVars.get(name) : null;
	}


```



对于支持的类型也说明的很详细。首先必须含有@PathVariable注解，其次如果是Map类型，必须要指定@PathVariable的值，即这个 ArgumentResolver只能获取一个uri变量。

#### 2.4.5 PathVariableMapMethodArgumentResolver 

获取多个uri变量

```java
@Override
	public boolean supportsParameter(MethodParameter parameter) {
		PathVariable annot = parameter.getParameterAnnotation(PathVariable.class);
		return ((annot != null) && (Map.class.isAssignableFrom(parameter.getParameterType()))
				&& (!StringUtils.hasText(annot.value())));
	}

public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
			NativeWebRequest webRequest, WebDataBinderFactory binderFactory) throws Exception {

		@SuppressWarnings("unchecked")
		Map<String, String> uriTemplateVars =
				(Map<String, String>) webRequest.getAttribute(
						HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE, RequestAttributes.SCOPE_REQUEST);

		if (!CollectionUtils.isEmpty(uriTemplateVars)) {
			return new LinkedHashMap<String, String>(uriTemplateVars);
		}
		else {
			return Collections.emptyMap();
		}
	}


```

它要求必须含有@PathVariable注解，并且必须是Map类型，并且@PathVariable注解的value没有值。同时我们可以从`PathVariableMapMethodArgumentResolver`和`PathVariableMethodArgumentResolver`上面看出，他们的取值都是从request的属性上进行获取的`webRequest.getAttribute( HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE, RequestAttributes.SCOPE_REQUEST);`也就是说，在解析完@RequestMapping匹配工作后，便将这些参数设置进request的属性上，属性名为HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE。

## 三、HandlerMethodArgumentResolver注册来源

至此，我们就要说明下HandlerMethodArgumentResolver的注册来源： 
它的来源分为两部分，一部分spring默认的HandlerMethodArgumentResolver，另一部分就是我们自定义的HandlerMethodArgumentResolver。 

先看mvc:annotation-driven中配置自定义的HandlerMethodArgumentResolver：

```xml
<mvc:annotation-driven >
		<mvc:argument-resolvers>
			<bean class="xxx"></bean>
		</mvc:argument-resolvers>
	</mvc:annotation-driven>  

```

在mvc:argument-resolvers标签下配置相应的自定义的HandlerMethodArgumentResolver。 
然后在mvc:annotation-driven的注解驱动类AnnotationDrivenBeanDefinitionParser中会有这样的代码：

```java
ManagedList<?> argumentResolvers = getArgumentResolvers(element, parserContext);

//略
if (argumentResolvers != null) {
			handlerAdapterDef.getPropertyValues().add("customArgumentResolvers", argumentResolvers);
		}


```

其中getArgumentResolvers就是获取我们自定义的HandlerMethodArgumentResolver

```java
private ManagedList<?> getArgumentResolvers(Element element, ParserContext parserContext) {
		Element resolversElement = DomUtils.getChildElementByTagName(element, "argument-resolvers");
		if (resolversElement != null) {
			ManagedList<BeanDefinitionHolder> argumentResolvers = extractBeanSubElements(resolversElement, parserContext);
			return wrapWebArgumentResolverBeanDefs(argumentResolvers, parserContext);
		}
		return null;
	}

```

从上面的代码可以看出，获取我们自定义的HandlerMethodArgumentResolver然后把它设置进RequestMappingHandlerAdapter的customArgumentResolvers参数中，RequestMappingHandlerAdapter有两个与HandlerMethodArgumentResolver有关的参数：

```java
private List<HandlerMethodArgumentResolver> customArgumentResolvers;  
private HandlerMethodArgumentResolverComposite argumentResolvers;  

```

HandlerMethodArgumentResolverComposite 也仅仅是内部存放一个`List<HandlerMethodArgumentResolver>`集合，同时本身又继承HandlerMethodArgumentResolver，所以它的实现都是靠内部的`List<HandlerMethodArgumentResolver>`集合来实现的。

```java
private final List<HandlerMethodArgumentResolver> argumentResolvers =
			new LinkedList<HandlerMethodArgumentResolver>();

//使用了适合高并发的ConcurrentHashMap来进行缓存
	private final Map<MethodParameter, HandlerMethodArgumentResolver> argumentResolverCache =
			new ConcurrentHashMap<MethodParameter, HandlerMethodArgumentResolver>(256);


	/**
	 * Return a read-only list with the contained resolvers, or an empty list.
	 */
	public List<HandlerMethodArgumentResolver> getResolvers() {
		return Collections.unmodifiableList(this.argumentResolvers);
	}

	/**
	 * Whether the given {@linkplain MethodParameter method parameter} is supported by any registered
	 * {@link HandlerMethodArgumentResolver}.
	 */
	@Override
	public boolean supportsParameter(MethodParameter parameter) {
		return getArgumentResolver(parameter) != null;
	}

	/**
	 * Iterate over registered {@link HandlerMethodArgumentResolver}s and invoke the one that supports it.
	 * @exception IllegalStateException if no suitable {@link HandlerMethodArgumentResolver} is found.
	 */
	@Override
	public Object resolveArgument(
			MethodParameter parameter, ModelAndViewContainer mavContainer,
			NativeWebRequest webRequest, WebDataBinderFactory binderFactory)
			throws Exception {

		HandlerMethodArgumentResolver resolver = getArgumentResolver(parameter);
		Assert.notNull(resolver, "Unknown parameter type [" + parameter.getParameterType().getName() + "]");
		return resolver.resolveArgument(parameter, mavContainer, webRequest, binderFactory);
	}

	/**
	 * Find a registered {@link HandlerMethodArgumentResolver} that supports the given method parameter.
	 */
	private HandlerMethodArgumentResolver getArgumentResolver(MethodParameter parameter) {
		HandlerMethodArgumentResolver result = this.argumentResolverCache.get(parameter);
		if (result == null) {
			for (HandlerMethodArgumentResolver methodArgumentResolver : this.argumentResolvers) {
				if (logger.isTraceEnabled()) {
					logger.trace("Testing if argument resolver [" + methodArgumentResolver + "] supports [" +
							parameter.getGenericParameterType() + "]");
				}
				if (methodArgumentResolver.supportsParameter(parameter)) {
					result = methodArgumentResolver;
					this.argumentResolverCache.put(parameter, result);
					break;
				}
			}
		}
		return result;
	}

```

在RequestMappingHandlerAdapter完成参数设置后，会调用afterPropertiesSet方法

```java
@Override
	public void afterPropertiesSet() {
		if (this.argumentResolvers == null) {
			List<HandlerMethodArgumentResolver> resolvers = getDefaultArgumentResolvers();
			this.argumentResolvers = new HandlerMethodArgumentResolverComposite().addResolvers(resolvers);
		}
		if (this.initBinderArgumentResolvers == null) {
			List<HandlerMethodArgumentResolver> resolvers = getDefaultInitBinderArgumentResolvers();
			this.initBinderArgumentResolvers = new HandlerMethodArgumentResolverComposite().addResolvers(resolvers);
		}
		if (this.returnValueHandlers == null) {
			List<HandlerMethodReturnValueHandler> handlers = getDefaultReturnValueHandlers();
			this.returnValueHandlers = new HandlerMethodReturnValueHandlerComposite().addHandlers(handlers);
		}
		initControllerAdviceCache();
	}


```

getDefaultArgumentResolvers方法完成了所有的HandlerMethodArgumentResolver的汇总，如下：

```java
private List<HandlerMethodArgumentResolver> getDefaultArgumentResolvers() {
		List<HandlerMethodArgumentResolver> resolvers = new ArrayList<HandlerMethodArgumentResolver>();

		// Annotation-based argument resolution
		resolvers.add(new RequestParamMethodArgumentResolver(getBeanFactory(), false));
		resolvers.add(new RequestParamMapMethodArgumentResolver());
		resolvers.add(new PathVariableMethodArgumentResolver());
		resolvers.add(new PathVariableMapMethodArgumentResolver());
		resolvers.add(new MatrixVariableMethodArgumentResolver());
		resolvers.add(new MatrixVariableMapMethodArgumentResolver());
		resolvers.add(new ServletModelAttributeMethodProcessor(false));
		resolvers.add(new RequestResponseBodyMethodProcessor(getMessageConverters()));
		resolvers.add(new RequestPartMethodArgumentResolver(getMessageConverters()));
		resolvers.add(new RequestHeaderMethodArgumentResolver(getBeanFactory()));
		resolvers.add(new RequestHeaderMapMethodArgumentResolver());
		resolvers.add(new ServletCookieValueMethodArgumentResolver(getBeanFactory()));
		resolvers.add(new ExpressionValueMethodArgumentResolver(getBeanFactory()));

		// Type-based argument resolution
		resolvers.add(new ServletRequestMethodArgumentResolver());
		resolvers.add(new ServletResponseMethodArgumentResolver());
		resolvers.add(new HttpEntityMethodProcessor(getMessageConverters()));
		resolvers.add(new RedirectAttributesMethodArgumentResolver());
		resolvers.add(new ModelMethodProcessor());
		resolvers.add(new MapMethodProcessor());
		resolvers.add(new ErrorsMethodArgumentResolver());
		resolvers.add(new SessionStatusMethodArgumentResolver());
		resolvers.add(new UriComponentsBuilderMethodArgumentResolver());

		// Custom arguments
//获取我们自定义的HandlerMethodArgumentResolver
		if (getCustomArgumentResolvers() != null) {
			resolvers.addAll(getCustomArgumentResolvers());
		}

		// Catch-all
		resolvers.add(new RequestParamMethodArgumentResolver(getBeanFactory(), true));
		resolvers.add(new ServletModelAttributeMethodProcessor(true));

		return resolvers;
	}

```

不仅汇总了spring默认的，同时加进来我们自定义的HandlerMethodArgumentResolver。

## 参考

 [SpringMVC源码总结（九）HandlerMethodArgumentResolver介绍](http://lgbolgger.iteye.com/blog/2111131)