# SlowXML

使用仓颉编写的轻量化 XML 解析库。

## 功能特性

- **轻量级**: 简洁的核心实现，无外部依赖
- **完整的 XML 支持**: 支持解析 XML 声明、DOCTYPE、注释、元素、属性、文本节点
- **自动转义**: 解析时自动反转义 `<`、`>`、`&` 等实体，输出时自动转义特殊字符
- **DOM 操作**: 提供丰富的 DOM 操作 API（查询、添加、删除、替换节点）
- **CSS 选择器**: 支持类似 CSS 的选择器语法（ID选择器、类选择器、标签选择器）
- **流式写入**: 提供 `XmlStreamWriter` 支持流式构建 XML 文档
- **链式调用**: Builder 模式支持链式配置

## 安装

```bash
cjpm add slowxml
```

## 快速上手

### 解析 XML

```cangjie
let xml = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<Library name="图书馆">
    <Book id="001">
        <Title>仓颉编程语言从入门到入土</Title>
        <Author>仓颉TPC</Author>
    </Book>
</Library>
"""

// 使用 Builder 模式配置解析器
let parser = XmlParser.builder()
    .parseHeader()     // 解析 XML 声明
    .parseComment()    // 解析注释
    .build()

// 解析 XML，返回 XmlDocument
let doc = parser.parse(xml).getOrThrow()

// 获取根元素
let root = doc.root
println("根节点: ${root.name}")  // 输出: Library

// 访问属性
println("图书馆名称: ${root.attr("name")}")  // 输出: 图书馆

// 获取所有子元素
let books = root.getElementsByTagName("Book")
for (book in books) {
    println("书籍ID: ${book.attr("id")}")
}

// 使用 CSS 选择器
let book = root.select("Book#001")
let title = root.select(".Book > Title")

// 获取文本内容
println("书名: ${root.getElementsByTagName("Title")[0].innerText}")
```

### 自动转义/反转义

解析时会自动将实体转换为实际字符，输出时会自动转义：

```cangjie
let xml = "<root>5 &lt; 10 && 10 &gt; 5</root>"
let doc = XmlParser.builder().build().parse(xml).getOrThrow()

// innerText 返回未转义的原始文本
println(doc.innerText)  // 输出: 5 < 10 && 10 > 5

// toXmlString 返回转义后的 XML
println(doc.toXmlString())
// 输出:
// <root>
//   5 &lt; 10 && 10 &gt; 5
// </root>
```

### 序列化 XML

```cangjie
let doc = XmlParser.builder().parse(xml).getOrThrow()

// 序列化为字符串
let xmlString = doc.toXmlString()
println(xmlString)

// 获取 innerText
println(doc.innerText)
```

### 使用 XmlStreamWriter 流式构建

```cangjie
let builder = XmlStreamWriter.string() // 流式创建字符串，使用 XmlStreamWriter.of(OutputStream) 直接输出到输出流中
builder.writeDecl()  // 默认 version="1.0" encoding="UTF-8"
builder.writeDoctype("xml")
builder.writeElementStart("root")
builder.writeComment("Hello!")
builder.writeElementStart("item")
builder.writeAttribute("id", "1")
builder.writeText("value <test>!")
builder.writeElementEnd()
builder.writeElementEnd()
// builder.flush() <- 使用 XmlStreamWriter.of(OutputStream) 直接输出到输出流中时需要添加这一行

let result = builder.build() // 仅 StringXmlStreamWriter 支持通过 build 函数直接转换为字符串
println(result)
```

输出:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xml>
<root>
    <!-- Hello! -->
    <item id="1">value <test>!</item>
</root>
```

### 自定义 XML 声明

```cangjie
let builder = XmlStreamWriter.string()
builder.writeDecl(version: "1.0", encoding: "GBK", standalone: false)
```

### 节点操作

```cangjie
let root = doc.root

// 添加子节点
let newElement = XmlElementNode("NewTag")
newElement.attr("key", "value")
root.appendChild(newElement)

// 移除节点
root.removeChild(newElement)

// 克隆节点
let cloned = root.clone()

// 查询元素
let element = root.getElementById("myId")
let elements = root.getElementsByTagName("Book")
```

### CSS 选择器

```cangjie
// ID 选择器
let element = root.select("#myId")

// 类选择器
let elements = root.selectAll(".myClass")

// 标签选择器
let books = root.selectAll("Book")

// 组合选择器
let element = root.select("container > item.active")
```

## API 概览

### XmlParserBuilder

```cangjie
XmlParser.builder()        // 创建 Builder
    .parseHeader()         // 启用 XML 声明解析
    .parseComment()        // 启用注释解析
    .disableAutoEscape()   // 禁用自动转义
    .build()               // 构建解析器
```

### XmlDocument

```cangjie
doc.root           // 根元素 (XmlElementNode)
doc.decl           // XML 声明 (XmlDeclNode)
doc.docType        // DOCTYPE (XmlDocTypeNode)
doc.innerText      // 所有文本内容
doc.toXmlString()  // 序列化为 XML 字符串
```

### XmlElementNode

```cangjie
element.name                    // 标签名
element.attributes              // 属性 HashMap
element.children                // 子节点 ArrayList
element.innerText               // 文本内容
element.attr("key")             // 获取属性
element.attr("key", "value")    // 设置属性
element.getElementById("id")    // 通过 ID 查询
element.getElementsByTagName("TagName")  // 通过标签名查询
element.select("selector")      // CSS 选择器查询
element.selectAll("selector")   // CSS 选择器查询（所有匹配）
element.appendChild(node)       // 添加子节点
element.removeChild(node)       // 移除子节点
element.clone()                 // 克隆节点
element.toXmlString()           // 序列化为 XML
```

### XmlStreamWriter

```cangjie
XmlStreamWriter.string()                          // 创建字符串写入器
XmlStreamWriter.of(outputStream)                  // 创建流写入器
writer.writeDecl(version, encoding, standalone)   // 写入 XML 声明
writer.writeDoctype(doctype)                      // 写入 DOCTYPE
writer.writeElementStart(name)                    // 写入开始标签
writer.writeAttribute(key, value)                 // 写入属性
writer.writeComment(content)                      // 写入注释
writer.writeText(content)                         // 写入文本（自动转义）
writer.writeElementEnd()                          // 写入结束标签
writer.flush()                                    // 刷新缓冲区
writer.build()                                    // 获取构建结果（仅 StringXmlStreamWriter）
```

## 许可证

MIT License