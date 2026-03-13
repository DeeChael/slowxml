package slowxml

import std.collection.*
import std.unicode.UnicodeStringExtension

public func escapeXmlText(text: String): String {
    let sb = StringBuilder()
    let lt = Rune(0x3c)
    let gt = Rune(0x3e)
    let amp = Rune(0x26)
    let quot = Rune(0x22)
    let apos = Rune(0x27)
    let semi = Rune(0x3b)
    for (c in text.toRuneArray()) {
        if (c == lt) {
            sb.append(amp)
            sb.append("lt")
            sb.append(semi)
        } else if (c == gt) {
            sb.append(amp)
            sb.append("gt")
            sb.append(semi)
        } else if (c == amp) {
            sb.append(amp)
            sb.append("amp")
            sb.append(semi)
        } else if (c == quot) {
            sb.append(amp)
            sb.append("quot")
            sb.append(semi)
        } else if (c == apos) {
            sb.append(amp)
            sb.append("apos")
            sb.append(semi)
        } else {
            sb.append(c)
        }
    }
    return sb.toString()
}

public func unescapeXmlText(text: String): String {
    var result = text
    let amp = Rune(0x26).toString()
    let lt = Rune(0x3c).toString()
    let gt = Rune(0x3e).toString()
    let quot = Rune(0x22).toString()
    let apos = Rune(0x27).toString()
    let semi = Rune(0x3b).toString()
    
    result = result.replace("${amp}lt${semi}", lt)
    result = result.replace("${amp}gt${semi}", gt)
    result = result.replace("${amp}amp${semi}", amp)
    result = result.replace("${amp}quot${semi}", quot)
    result = result.replace("${amp}apos${semi}", apos)
    return result
}

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
        return escapeXmlText(_content)
    }

    public override func toXmlString(_: Int64): String {
        return toXmlString()
    }

}

public class XmlCommentNode <: XmlNode {

    private let _content: String
    
    public prop content: String {
        get() {
            return this._content
        }
    }
    
    public override prop innerText: String {
        get() {
            return ""
        }
    }

    public init(content: String) {
        this._content = content.trimAscii()
    }

    public override func toXmlString(): String {
        return "<!-- ${_content} -->"
    }

    public override func toXmlString(indent: Int64): String {
        let space = "  " * indent
        return "${space}<!-- ${_content} -->\n"
    }

}

public class XmlDeclNode <: XmlNode {

    private let _version: String
    private var _encoding: String = "UTF-8"
    private var _standalone: ?Bool = None
    
    public prop version: String {
        get() {
            return this._version
        }
    }
    
    public prop encoding: String {
        get() {
            return this._encoding
        }
    }
    
    public prop standalone: ?Bool {
        get() {
            return this._standalone
        }
    }
    
    public override prop innerText: String {
        get() {
            return ""
        }
    }

    public init(version: String) {
        this._version = version
    }

    public func setEncoding(enc: String): XmlDeclNode {
        this._encoding = enc
        return this
    }

    public func setStandalone(stand: Bool): XmlDeclNode {
        this._standalone = Some(stand)
        return this
    }

    public override func toXmlString(): String {
        return toXmlString(0)
    }

    public override func toXmlString(indent: Int64): String {
        let sb = StringBuilder()
        let space = "  " * indent
        sb.append("${space}<?xml version=\"${_version}\" encoding=\"${_encoding}\"")
        if (let Some(stand) <- _standalone) {
            sb.append(" standalone=\"${if (stand) { "yes" } else { "no" }}\"")
        }
        sb.append("?>\n")
        return sb.toString()
    }

}

public class XmlDocTypeNode <: XmlNode {

    private let _content: String
    
    public prop content: String {
        get() {
            return this._content
        }
    }
    
    public override prop innerText: String {
        get() {
            return ""
        }
    }

    public init(content: String) {
        this._content = content
    }

    public override func toXmlString(): String {
        return "<!DOCTYPE ${_content}>"
    }

    public override func toXmlString(indent: Int64): String {
        let space = "  " * indent
        return "${space}<!DOCTYPE ${_content}>\n"
    }

}

public class XmlDocument <: ToString {

    protected var rootElement: XmlElementNode
    public var decl: ?XmlDeclNode = None
    public var docType: ?XmlDocTypeNode = None

    public init(name: String) {
        this.rootElement = XmlElementNode(name)
    }

    public prop root: XmlElementNode {
        get() {
            return rootElement
        }
    }

    public prop innerText: String {
        get() {
            return rootElement.innerText
        }
    }

    public func toXmlString(): String {
        return toXmlString(0)
    }

    public func toXmlString(indent: Int64): String {
        let sb = StringBuilder()
        
        if (let Some(d) <- decl) {
            sb.append(d.toXmlString(indent))
        }
        if (let Some(t) <- docType) {
            sb.append(t.toXmlString(indent))
        }
        
        sb.append(rootElement.toXmlString(indent))
        
        return sb.toString()
    }

    public override func toString(): String {
        return toXmlString()
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
            let escapedValue = escapeXmlText(v)
            sb.append(" ${k}=\"${escapedValue}\"")
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

    public func appendChild(node: XmlNode): XmlElementNode {
        children.add(node)
        return this
    }

    public func prependChild(node: XmlNode): XmlElementNode {
        let newChildren = ArrayList<XmlNode>()
        newChildren.add(node)
        for (child in children) {
            newChildren.add(child)
        }
        this.children.clear()
        for (child in newChildren) {
            this.children.add(child)
        }
        return this
    }

    public func removeChild(node: XmlNode): Bool {
        for (i in 0..children.size) {
            if (matchNode(children[i], node)) {
                children.remove(i..i+1)
                return true
            }
        }
        return false
    }

    public func removeChildAt(index: Int64): ?XmlNode {
        if (index < 0 || index >= children.size) {
            return None
        }
        let node = children[index]
        children.remove(index..index+1)
        return node
    }

    private func matchNode(a: XmlNode, b: XmlNode): Bool {
        if (a is XmlTextNode && b is XmlTextNode) {
            if (let Some(textA) <- (a as XmlTextNode)) {
                if (let Some(textB) <- (b as XmlTextNode)) {
                    return textA.content == textB.content
                }
            }
        }
        if (a is XmlElementNode && b is XmlElementNode) {
            if (let Some(elemA) <- (a as XmlElementNode)) {
                if (let Some(elemB) <- (b as XmlElementNode)) {
                    return elemA.name == elemB.name
                }
            }
        }
        if (a is XmlCommentNode && b is XmlCommentNode) {
            if (let Some(commentA) <- (a as XmlCommentNode)) {
                if (let Some(commentB) <- (b as XmlCommentNode)) {
                    return commentA.content == commentB.content
                }
            }
        }
        if (a is XmlDeclNode && b is XmlDeclNode) {
            if (let Some(declA) <- (a as XmlDeclNode)) {
                if (let Some(declB) <- (b as XmlDeclNode)) {
                    return declA.version == declB.version
                }
            }
        }
        if (a is XmlDocTypeNode && b is XmlDocTypeNode) {
            if (let Some(docTypeA) <- (a as XmlDocTypeNode)) {
                if (let Some(docTypeB) <- (b as XmlDocTypeNode)) {
                    return docTypeA.content == docTypeB.content
                }
            }
        }
        return false
    }

    public func getChildAt(index: Int64): ?XmlNode {
        if (index < 0 || index >= children.size) {
            return None
        }
        return children[index]
    }

    public func getChildren(): ArrayList<XmlNode> {
        return children
    }

    public func getFirstChild(): ?XmlNode {
        if (children.isEmpty()) {
            return None
        }
        return children[0]
    }

    public func getLastChild(): ?XmlNode {
        if (children.isEmpty()) {
            return None
        }
        return children[children.size - 1]
    }

    public func hasChildren(): Bool {
        return !children.isEmpty()
    }

    public func clearChildren(): XmlElementNode {
        children.clear()
        return this
    }

    public func removeAttribute(key: String): XmlElementNode {
        attributes.remove(key)
        return this
    }

    public func hasAttribute(key: String): Bool {
        return attributes.contains(key)
    }

    public func getAttributes(): HashMap<String, String> {
        return attributes
    }

    public func clone(): XmlElementNode {
        let cloned = XmlElementNode(_name)
        for ((k, v) in attributes) {
            cloned.attributes[k] = v
        }
        for (child in children) {
            if (child is XmlElementNode) {
                if (let Some(element) <- (child as XmlElementNode)) {
                    cloned.children.add(element.clone())
                }
            } else if (child is XmlTextNode) {
                if (let Some(text) <- (child as XmlTextNode)) {
                    cloned.children.add(XmlTextNode(text.content))
                }
            } else if (child is XmlCommentNode) {
                if (let Some(comment) <- (child as XmlCommentNode)) {
                    cloned.children.add(XmlCommentNode(comment.content))
                }
            } else if (child is XmlDeclNode) {
                if (let Some(decl) <- (child as XmlDeclNode)) {
                    let newDecl = XmlDeclNode(decl.version)
                    if (decl.encoding != "UTF-8") {
                        newDecl.setEncoding(decl.encoding)
                    }
                    if (let Some(stand) <- decl.standalone) {
                        newDecl.setStandalone(stand)
                    }
                    cloned.children.add(newDecl)
                }
            } else if (child is XmlDocTypeNode) {
                if (let Some(docType) <- (child as XmlDocTypeNode)) {
                    cloned.children.add(XmlDocTypeNode(docType.content))
                }
            }
        }
        return cloned
    }

    public func hasChild(predicate: (XmlNode) -> Bool): Bool {
        for (child in children) {
            if (predicate(child)) {
                return true
            }
        }
        return false
    }

    public func findChild(predicate: (XmlNode) -> Bool): ?XmlNode {
        for (child in children) {
            if (predicate(child)) {
                return child
            }
        }
        return None
    }

    public func findChildren(predicate: (XmlNode) -> Bool): ArrayList<XmlNode> {
        let results = ArrayList<XmlNode>()
        for (child in children) {
            if (predicate(child)) {
                results.add(child)
            }
        }
        return results
    }

    public func replaceChild(oldNode: XmlNode, newNode: XmlNode): Bool {
        for (i in 0..children.size) {
            if (matchNode(children[i], oldNode)) {
                children[i] = newNode
                return true
            }
        }
        return false
    }

    public func insertBefore(referenceNode: XmlNode, newNode: XmlNode): Bool {
        for (i in 0..children.size) {
            if (matchNode(children[i], referenceNode)) {
                let newChildren = ArrayList<XmlNode>()
                for (j in 0..i) {
                    newChildren.add(children[j])
                }
                newChildren.add(newNode)
                for (j in i..children.size) {
                    newChildren.add(children[j])
                }
                this.children.clear()
                for (child in newChildren) {
                    this.children.add(child)
                }
                return true
            }
        }
        return false
    }

    public func insertAfter(referenceNode: XmlNode, newNode: XmlNode): Bool {
        for (i in 0..children.size) {
            if (matchNode(children[i], referenceNode)) {
                let newChildren = ArrayList<XmlNode>()
                for (j in 0..i + 1) {
                    newChildren.add(children[j])
                }
                newChildren.add(newNode)
                for (j in i + 1..children.size) {
                    newChildren.add(children[j])
                }
                this.children.clear()
                for (child in newChildren) {
                    this.children.add(child)
                }
                return true
            }
        }
        return false
    }

}