package slowxml

import std.collection.*
import std.unicode.UnicodeStringExtension

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

    public func getElementById(id: String): ?XmlElementNode {
        if (id.isEmpty() || id.isBlank()) {
            return None
        }

        if (this.attr("id") == id) {
            return this
        }

        for (child in children) {
            if (!(child is XmlElementNode)) {
                continue
            }
            if (let Some(element) <- (child as XmlElementNode)) {
                if (let Some(found) <- element.getElementById(id)) {
                    return found
                }
            }
        }

        return None
    }

    public func getElementsByTagName(name: String, recursive!: Bool = true): ArrayList<XmlElementNode> {
        let results = ArrayList<XmlElementNode>()
        
        if (recursive) {
            _collectElementsByTagName(this, name, results)
        } else {
            for (child in children) {
                if (!(child is XmlElementNode)) {
                    continue
                }
                if (let Some(e) <- (child as XmlElementNode)) {
                    if (name == "*" || e.name == name) {
                        results.add(e)
                    }
                }
            }
        }
        
        return results
    }

    public func select(query: String): ?XmlElementNode {
        let results = selectAll(query)
        return if (results.size > 0) { results[0] } else { None }
    }

    public func selectAll(query: String): ArrayList<XmlElementNode> {
        let tokens = query.split(" ")
        var currentCandidates = ArrayList<XmlElementNode>([this])

        var i = 0
        while (i < tokens.size) {
            let token = tokens[i].trimAscii()
            if (token.isEmpty()) { i++; continue }

            let nextCandidates = ArrayList<XmlElementNode>()
            
            if (token == ">") {
                i++
                let childToken = tokens[i].trimAscii()
                for (parent in currentCandidates) {
                    for (child in parent.getElementsByTagName("*", recursive: false)) {
                        if (matchCriteria(child, childToken)) {
                            nextCandidates.add(child)
                        }
                    }
                }
            } else {
                for (parent in currentCandidates) {
                    for (descendant in parent.getElementsByTagName("*", recursive: true)) {
                        if (matchCriteria(descendant, token)) {
                            nextCandidates.add(descendant)
                        }
                    }
                }
            }
            
            currentCandidates = nextCandidates
            if (currentCandidates.size == 0) { break }
            i++
        }

        return currentCandidates
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

    private func _collectElementsByTagName(current: XmlElementNode, targetName: String, results: ArrayList<XmlElementNode>): Unit {
        for (child in current.children) {
            if (!(child is XmlElementNode)) {
                continue
            }
            if (let Some(element) <- (child as XmlElementNode)) {
                if (targetName == "*" || element.name == targetName) {
                    results.add(element)
                }
                _collectElementsByTagName(element, targetName, results)
            }
        }
    }

    private func matchCriteria(el: XmlElementNode, criteria: String): Bool {
        if (criteria.startsWith("#")) {
            return el.attr("id") == criteria[1..]
        }

        if (criteria.startsWith(".")) {
            let targetClass = criteria[1..]
            let classes = el.attr("class").split(" ")
            return classes.contains(targetClass)
        }

        if (criteria.contains(".")) {
            let parts = criteria.split(".")
            let tagName = parts[0]
            let className = parts[1]
            let isTagMatch = tagName.isEmpty() || el.name == tagName
            let classes = el.attr("class").split(" ")
            return isTagMatch && classes.contains(className)
        }

        return el.name == criteria || criteria == "*"
    }

}