package slowxml

import std.collection.*

public abstract class XmlNode <: ToString {

    public func toXmlString(): String
    public func toXmlString(indent: Int64): String

    public override func toString(): String {
        return this.toXmlString()
    }

}

public class XmlTextNode <: XmlNode {

    private let _content: String
    
    public prop content: String {
        get() {
            return this._content
        }
    }

    public init(content: String) {
        this._content = content
    }

    public override func toXmlString(): String {
        return _content
    }

    public override func toXmlString(indent: Int64): String {
        return _content
    }

}

public class XmlElementNode <: XmlNode {

    private let _name: String
    protected let attributes: HashMap<String, String> = HashMap<String, String>()
    public let children: ArrayList<XmlNode> = ArrayList<XmlNode>()

    public prop name: String {
        get() {
            return this._name
        }
    }

    public init(name: String) {
        this._name = name
    }

    public func attr(key: String): String {
        attributes.get(key).getOrDefault { "" }
    }

    public override func toXmlString(): String {
        return this.toXmlString(0)
    }

    public override func toXmlString(indent: Int64): String {
        let sb = StringBuilder()
        let space = "  " * indent

        sb.append("${space}<${this._name}")
        for ((k, v) in attributes) {
            sb.append(" ${k}=\"${v}\"")
        }

        if (children.size == 0) {
            sb.append(" />\n")
        } else {
            sb.append(">")
            // 如果子节点全是文本，不换行，保持紧凑
            let containsOnlyText = children.size == 1 && children[0] is XmlTextNode
            
            if (!containsOnlyText) { sb.append("\n") }
            
            for (child in children) {
                // 这里的缩进逻辑可以根据 child 类型微调
                if (containsOnlyText) {
                    sb.append(child.toXmlString(0))
                } else {
                    sb.append(child.toXmlString(indent + 1))
                }
            }
            
            if (!containsOnlyText) { sb.append("${space}") }
            sb.append("</${name}>\n")
        }
        return sb.toString()
    }

}