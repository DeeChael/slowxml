# SlowXML
使用仓颉编写的轻量化 XML 解析库。

## 🚀 快速上手
解析 XML 字符串
```cangjie
let input = """
<?xml version="1.0" encoding="UTF-8"?>
<Library name="图书馆">
    <Book id="001">
        <Title>仓颉编程语言从入门到入土</Title>
        <Author>仓颉TPC</Author>
    </Book>
</Library>
"""
let parser = XmlParser(input)
if (let Some(root) <- parser.parse()) {
    println("根节点: ${root.name}") // 输出: Library
    
    // 访问属性
    println("图书馆名称: ${root.attr("name")}")
    
    // 遍历子节点
    for (child in root.children) {
        if (let Some(element) <- child as XmlElementNode) { // 如果是文本内容，请使用 XmlTextNode
            println("发现标签: ${element.name}")
        }
    }
}
```
操作节点与序列化
```cangjie
// 修改属性
root.attributes.put("location", "山东")

// 序列化为字符串（支持自动缩进与混合内容保留）
let xmlString = root.toXmlString()
println(xmlString)
```