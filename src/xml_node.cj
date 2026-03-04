package slowxml

import std.collection.*

public abstract class XmlNode <: ToString {

    public prop innerText: String

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
    
    public override prop innerText: String {
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
    
    public override prop innerText: String {
        get() {
            let builder = StringBuilder()
            for (child in children) {
                builder.append(child.innerText)
            }
            return builder.toString().trimAscii()
        }
    }

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

    public func attr(key: String, value: String) {
        attributes[key] = value
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
            let containsOnlyText = children.size == 1 && children[0] is XmlTextNode
            
            if (!containsOnlyText) { sb.append("\n") }
            
            for (child in children) {
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