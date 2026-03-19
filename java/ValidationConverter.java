import jakarta.validation.constraints.*;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.annotation.Annotation;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.util.*;
import org.hibernate.validator.constraints.Length;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.RestController;
import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.nodes.Tag;
import org.yaml.snakeyaml.representer.Representer;

/**
 * 暂不支持 param-rules 配置校验方法参数本身
 *
 * @author tangKaichuan
 */
public class ValidationConverter {

  public static final String FIELD_SEP = "_";

  /**
   * 主方法，直接运行转换器
   *
   * @param args 参数
   */
  public static void main(String[] args) {
    // 修改为你的项目基础包名
    new ValidationConverter().scanAndConvert("com.xzzh.smartcloud.service.hub");
    System.exit(0);
  }

  private static final Map<Class<?>, String> ANNOTATION_TYPE_MAPPING = new LinkedHashMap<>();

  static {
    ANNOTATION_TYPE_MAPPING.put(NotNull.class, "notNull");
    ANNOTATION_TYPE_MAPPING.put(NotBlank.class, "notBlank");
    ANNOTATION_TYPE_MAPPING.put(NotEmpty.class, "notEmpty");
    ANNOTATION_TYPE_MAPPING.put(Size.class, "maxSize");
    ANNOTATION_TYPE_MAPPING.put(Pattern.class, "pattern");
    ANNOTATION_TYPE_MAPPING.put(Max.class, "maxValue");
    ANNOTATION_TYPE_MAPPING.put(Min.class, "minValue");
    ANNOTATION_TYPE_MAPPING.put(Length.class, "maxLength");
  }

  // 使用 TreeMap 保证最终输出的 Key 是有序的
  private final Map<String, Map<String, Map<String, Map<String, Map<String, List<Rule>>>>>>
      validationRuleMap = new TreeMap<>();

  public void scanAndConvert(String basePackage) {
    try {
      // 扫描所有Controller类
      Set<Class<?>> controllers = findControllers(basePackage);

      for (Class<?> controller : controllers) {
        processController(controller);
      }

      // 生成YAML配置
      generateYamlConfig();

    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private Set<Class<?>> findControllers(String basePackage) throws Exception {
    // 使用 TreeSet 对类进行排序
    Set<Class<?>> controllers = new TreeSet<>(Comparator.comparing(Class::getName));
    String baseDir = basePackage.replace('.', '/');
    String classpath =
        Objects.requireNonNull(ValidationConverter.class.getClassLoader().getResource(baseDir))
            .getFile();
    scanDir(new File(classpath), basePackage, controllers);
    return controllers;
  }

  private void scanDir(File dir, String basePackage, Set<Class<?>> controllers) throws Exception {
    File[] files = dir.listFiles();
    if (files != null) {
      for (File file : files) {
        if (file.isDirectory()) {
          scanDir(file, basePackage + "." + file.getName(), controllers);
        } else if (file.getName().endsWith(".class")) {
          String className =
              basePackage + "." + file.getName().substring(0, file.getName().length() - 6);
          Class<?> clazz = Class.forName(className);
          if (clazz.isAnnotationPresent(RestController.class)) {
            controllers.add(clazz);
          }
        }
      }
    }
  }

  private void processController(Class<?> controllerClass) {
    Method[] methods = controllerClass.getDeclaredMethods();
    // 对方法进行排序，确保每次生成顺序一致
    Arrays.sort(methods, Comparator.comparing(Method::getName));

    for (Method method : methods) {
      // 忽略编译器生成的合成方法（如 Lambda 表达式生成的方法）和桥接方法
      if (method.isSynthetic() || method.isBridge()) {
        continue;
      }

      if (method.getParameterCount() > 0) {
        String methodIdentifier = controllerClass.getSimpleName() + "-" + method.getName();
        processMethod(method, methodIdentifier);
      }
    }
  }

  private void processMethod(Method method, String methodIdentifier) {
    Parameter[] parameters = method.getParameters();
    for (Parameter parameter : parameters) {
      processParameter(parameter, methodIdentifier);
    }
  }

  private void processParameter(Parameter parameter, String methodIdentifier) {
    String paramName = parameter.getName();
    Class<?> paramType = parameter.getType();

    // 获取参数上的 @Validated 注解
    Validated validatedAnnotation = parameter.getAnnotation(Validated.class);
    Class<?>[] validationGroups = null;
    if (validatedAnnotation != null) {
      validationGroups = validatedAnnotation.value();
    }

    // 处理参数上的直接注解，传入验证组
    processAnnotations(
        parameter.getAnnotations(), methodIdentifier, paramName, "", validationGroups);

    // 处理参数类型的字段注解，传入验证组
    processFields(paramType, methodIdentifier, paramName, "", validationGroups);
  }

  /** 添加已处理类型的跟踪集合 */
  private final Set<Class<?>> processedTypes = new HashSet<>();

  private void processFields(
      Class<?> type,
      String methodIdentifier,
      String paramName,
      String parentPath,
      Class<?>[] validationGroups) {
    if (shouldSkipType(type)) {
      return;
    }

    // 添加到已处理类型集合
    processedTypes.add(type);

    try {
      for (Field field : type.getDeclaredFields()) {
        String fieldPath =
            parentPath.isEmpty() ? field.getName() : parentPath + FIELD_SEP + field.getName();
        processAnnotations(
            field.getAnnotations(), methodIdentifier, paramName, fieldPath, validationGroups);

        Class<?> fieldType = field.getType();

        // 处理集合类型
        if (Collection.class.isAssignableFrom(fieldType)) {
          processCollectionField(field, methodIdentifier, paramName, fieldPath, validationGroups);
        }
        // 处理嵌套对象
        else if (isValidNestedType(fieldType)) {
          processFields(fieldType, methodIdentifier, paramName, fieldPath, validationGroups);
        }
      }
    } finally {
      // 处理完成后移除类型，允许同一类型在不同路径下被处理
      processedTypes.remove(type);
    }
  }

  private boolean shouldSkipType(Class<?> type) {
    // 跳过已处理的类型、基本类型、JDK内置类型等
    return type == null
        || type.isPrimitive()
        || type.getName().startsWith("java.lang")
        || type.getName().startsWith("java.util")
        || processedTypes.contains(type);
  }

  private boolean isValidNestedType(Class<?> type) {
    // 判断是否是有效的嵌套类型
    return !type.isPrimitive() && !type.getName().startsWith("java.") && !type.isEnum();
  }

  private void processCollectionField(
      Field field,
      String methodIdentifier,
      String paramName,
      String fieldPath,
      Class<?>[] validationGroups) {
    // 处理集合类型的字段
    Class<?> fieldType = field.getType();

    // 如果是Collection类型，尝试获取泛型类型
    if (Collection.class.isAssignableFrom(fieldType)) {
      try {
        java.lang.reflect.ParameterizedType paramType =
            (java.lang.reflect.ParameterizedType) field.getGenericType();
        Class<?> genericType = (Class<?>) paramType.getActualTypeArguments()[0];

        // 如果集合元素是自定义类型，则处理其字段
        if (isValidNestedType(genericType)) {
          processFields(genericType, methodIdentifier, paramName, fieldPath, validationGroups);
        }
      } catch (Exception e) {
        // 无法确定泛型类型时忽略
        System.out.println("Warning: Unable to process collection field: " + fieldPath);
      }
    }
  }

  private void processAnnotations(
      Annotation[] annotations,
      String methodIdentifier,
      String paramName,
      String fieldPath,
      Class<?>[] validationGroups) {
    for (Annotation annotation : annotations) {
      String type = ANNOTATION_TYPE_MAPPING.get(annotation.annotationType());
      if (type != null) {
        // 检查注解的组是否匹配
        if (shouldProcessAnnotation(annotation, validationGroups)) {
          Rule rule = convertAnnotationToRule(annotation, type);
          addRule(methodIdentifier, paramName, fieldPath, rule);
        }
      }
    }
  }

  private boolean shouldProcessAnnotation(Annotation annotation, Class<?>[] validationGroups) {
    if (validationGroups == null || validationGroups.length == 0) {
      // 如果没有指定验证组，则处理所有注解
      return true;
    }

    try {
      Method groupsMethod = annotation.annotationType().getMethod("groups");
      Class<?>[] annotationGroups = (Class<?>[]) groupsMethod.invoke(annotation);

      // 如果注解没有指定组，且存在验证组要求，则处理该注解
      if (annotationGroups.length == 0) {
        return true;
      }

      // 检查注解的组是否包含在验证组中
      for (Class<?> validationGroup : validationGroups) {
        for (Class<?> annotationGroup : annotationGroups) {
          if (validationGroup.equals(annotationGroup)) {
            return true;
          }
        }
      }
      return false;
    } catch (Exception e) {
      // 如果注解没有groups方法，则视为不匹配
      return false;
    }
  }

  private Rule convertAnnotationToRule(Annotation annotation, String type) {
    Rule rule = new Rule();
    rule.setType(type);

    try {
      if (annotation instanceof Size size) {
        rule.setValue(String.valueOf(size.max()));
        rule.setMessage(size.message());
      } else if (annotation instanceof Pattern pattern) {
        rule.setValue(pattern.regexp());
        rule.setMessage(pattern.message());
      } else if (annotation instanceof Max max) {
        rule.setValue(String.valueOf(max.value()));
        rule.setMessage(max.message());
      } else if (annotation instanceof Min min) {
        rule.setValue(String.valueOf(min.value()));
        rule.setMessage(min.message());
      } else if (annotation instanceof Length length) {
        rule.setValue(String.valueOf(length.max()));
        rule.setMessage(length.message());
      } else {
        // 对于简单注解，只设置消息
        Method messageMethod = annotation.annotationType().getMethod("message");
        rule.setMessage((String) messageMethod.invoke(annotation));
      }
    } catch (Exception e) {
      e.printStackTrace();
    }

    return rule;
  }

  private void addRule(String methodIdentifier, String paramName, String fieldPath, Rule rule) {
    List<Rule> rules =
        validationRuleMap
            .computeIfAbsent(methodIdentifier, k -> new TreeMap<>())
            .computeIfAbsent("methodRuleMap", k -> new TreeMap<>())
            .computeIfAbsent(paramName, k -> new TreeMap<>())
            .computeIfAbsent("field-rules-map", k -> new TreeMap<>())
            .computeIfAbsent(fieldPath, k -> new ArrayList<>());

    rules.add(rule);

    // 对规则列表进行排序，确保同一字段上的多个规则顺序一致（例如 notNull 在前，maxSize 在后）
    rules.sort(Comparator.comparing(r -> (String) r.get("type")));
  }

  private static class FlowStyleRepresenter extends Representer {
    public FlowStyleRepresenter(DumperOptions options) {
      super(options);
      this.representers.put(
          Rule.class, data -> representMapping(Tag.MAP, (Rule) data, DumperOptions.FlowStyle.FLOW));
    }
  }

  private void generateYamlConfig() {
    // 使用 LinkedHashMap 保持顶层结构的插入顺序
    Map<String, Object> config = new LinkedHashMap<>();
    Map<String, Object> validationConfig = new LinkedHashMap<>();
    Map<String, Object> ruleConfig = new LinkedHashMap<>();

    ruleConfig.put("enabled", true);
    ruleConfig.put("validationRuleMap", validationRuleMap);
    validationConfig.put("rules", ruleConfig);
    config.put("validation", validationConfig);

    DumperOptions options = new DumperOptions();
    options.setDefaultFlowStyle(DumperOptions.FlowStyle.BLOCK);
    options.setIndent(2);
    // 关键设置：设置超大的行宽，强制单行输出
    options.setWidth(Integer.MAX_VALUE);

    Yaml yaml = new Yaml(new FlowStyleRepresenter(options), options);

    try (FileWriter writer = new FileWriter("src/main/resources/rules.yaml")) {
      yaml.dump(config, writer);
      System.out.println("验证配置已生成到: src/main/resources/rules.yaml");
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  private static class Rule extends LinkedHashMap<String, Object> {
    public Rule() {
      super();
    }

    public void setType(String type) {
      put("type", type);
    }

    public void setValue(String value) {
      put("value", value);
    }

    public void setMessage(String message) {
      put("message", message);
    }
  }
}
