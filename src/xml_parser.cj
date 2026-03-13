package slowxml

import std.collection.*

public class XmlParserBuilder {
    private var parseCommentEnabled: Bool = false
    private var parseHeaderEnabled: Bool = false
    private var autoEscapeEnabled: Bool = true

    public init() {}

    public func parseComment(): XmlParserBuilder {
        this.parseCommentEnabled = true
        return this
    }

    public func parseHeader(): XmlParserBuilder {
        this.parseHeaderEnabled = true
        return this
    }

    public func disableAutoEscape(): XmlParserBuilder {
        this.autoEscapeEnabled = false
        return this
    }

    public func build(): XmlParser {
        return XmlParser(this.parseCommentEnabled, this.parseHeaderEnabled, this.autoEscapeEnabled)
    }
}

public class XmlParser {

    private let parseComment: Bool
    private let parseHeader: Bool
    private let autoEscape: Bool

    public init(parseComment: Bool, parseHeader: Bool, autoEscape: Bool) {
        this.parseComment = parseComment
        this.parseHeader = parseHeader
        this.autoEscape = autoEscape
    }

    public static func default(): XmlParser {
        return XmlParserBuilder().build()
    }

    public static func builder(): XmlParserBuilder {
        return XmlParserBuilder()
    }

    public func parse(xml: String): ?XmlDocument {
        let lexer = XmlLexer(xml)
        var currentToken = lexer.nextToken()
        
        var doc = XmlDocument("")
        var rootElement: ?XmlElementNode = None
        
        while (true) {
            match (currentToken) {
                case XmlToken.Header(content) =>
                    if (parseHeader) {
                        let (version, encoding, standalone) = _parseDeclContent(content)
                        let decl = XmlDeclNode(version)
                        if (encoding != "UTF-8") {
                            decl.setEncoding(encoding)
                        }
                        if (let Some(stand) <- standalone) {
                            decl.setStandalone(stand)
                        }
                        doc.decl = Some(decl)
                    }
                    currentToken = lexer.nextToken()
                case XmlToken.DocType(content) =>
                    if (parseHeader) {
                        let docType = XmlDocTypeNode(content)
                        doc.docType = Some(docType)
                    }
                    currentToken = lexer.nextToken()
                case XmlToken.Comment(content) =>
                    if (parseComment) {
                        let comment = XmlCommentNode(content)
                        if (rootElement.isNone()) {
                            rootElement = XmlElementNode("")
                        }
                        if (let Some(root) <- rootElement) {
                            root.children.add(comment)
                        }
                    }
                    currentToken = lexer.nextToken()
                case XmlToken.Text(content) =>
                    if (content.trimAscii().size > 0) {
                        if (rootElement.isNone()) {
                            rootElement = XmlElementNode("")
                        }
                        if (let Some(root) <- rootElement) {
                            let textContent = if (autoEscape) { unescapeXmlText(content) } else { content }
                            root.children.add(XmlTextNode(textContent))
                        }
                    }
                    currentToken = lexer.nextToken()
                case XmlToken.StartTag(name) =>
                    let (element, nextToken) = parseElement(name, lexer, currentToken)
                    if (rootElement.isNone()) {
                        rootElement = Some(element)
                    } else {
                        if (let Some(root) <- rootElement) {
                            root.children.add(element)
                        }
                    }
                    currentToken = nextToken
                case XmlToken.EOF => break
                case _ => 
                    currentToken = lexer.nextToken()
            }
        }

        if (let Some(root) <- rootElement) {
            doc.rootElement = root
        }
        
        if (doc.rootElement.name.isEmpty() && doc.rootElement.children.isEmpty()) {
            return None
        }
        
        return Some(doc)
    }

    private func _parseDeclContent(content: String): (String, String, ?Bool) {
        var version = "1.0"
        var encoding = "UTF-8"
        var standalone: ?Bool = None
        
        let parts = content.split(" ")
        if (parts.size > 1) {
            for (i in 1..parts.size) {
                let part = parts[i].trimAscii()
                if (part.isEmpty()) {
                    continue
                }
                let kv = part.split("=")
                if (kv.size == 2) {
                    let key = kv[0].trimAscii()
                    var value = kv[1].trimAscii()
                    if (value.startsWith('"') && value.endsWith('"')) {
                        value = value[1..value.size - 1]
                    }
                    if (key == "version") {
                        version = value
                    } else if (key == "encoding") {
                        encoding = value
                    } else if (key == "standalone") {
                        standalone = Some(value == "yes")
                    }
                }
            }
        }
        
        return (version, encoding, standalone)
    }

    private func parseElement(name: String, lexer: XmlLexer, currentToken: XmlToken): (XmlElementNode, XmlToken) {
        let element = XmlElementNode(name)
        var token = currentToken

        match (token) {
            case XmlToken.SelfClosing =>
                let nextToken = lexer.nextToken()
                return (element, nextToken)
            case XmlToken.TagEnd =>
                let nextToken = lexer.nextToken()
                token = nextToken
            case _ => 
                token = lexer.nextToken()
        }

        while (true) {
            match (token) {
                case XmlToken.AttrName(key) =>
                    token = lexer.nextToken()
                    match (token) {
                        case XmlToken.AttrValue(value) => 
                            let finalValue = if (autoEscape) { unescapeXmlText(value) } else { value }
                            element.attributes[key] = finalValue
                            token = lexer.nextToken()
                        case _ => throw XmlParsingException("Expected attribute value")
                    }
                case XmlToken.TagEnd => 
                    token = lexer.nextToken()
                    break
                case XmlToken.SelfClosing => 
                    token = lexer.nextToken()
                    return (element, token)
                case _ => 
                    break
            }
        }

        while (true) {
            match (token) {
                case XmlToken.Text(content) =>
                    if (content.trimAscii().size > 0) {
                        let textContent = if (autoEscape) { unescapeXmlText(content) } else { content }
                        element.children.add(XmlTextNode(textContent))
                    }
                    token = lexer.nextToken()

                case XmlToken.Comment(content) =>
                    if (parseComment) {
                        element.children.add(XmlCommentNode(content))
                    }
                    token = lexer.nextToken()

                case XmlToken.Header(content) =>
                    if (parseHeader) {
                        let (version, encoding, standalone) = _parseDeclContent(content)
                        let decl = XmlDeclNode(version)
                        if (encoding != "UTF-8") {
                            decl.setEncoding(encoding)
                        }
                        if (let Some(stand) <- standalone) {
                            decl.setStandalone(stand)
                        }
                        element.children.add(decl)
                    }
                    token = lexer.nextToken()

                case XmlToken.DocType(content) =>
                    if (parseHeader) {
                        let docType = XmlDocTypeNode(content)
                        element.children.add(docType)
                    }
                    token = lexer.nextToken()

                case XmlToken.StartTag(childName) =>
                    let (childElement, nextToken) = parseElement(childName, lexer, token)
                    element.children.add(childElement)
                    token = nextToken

                case XmlToken.EndTag(endName) =>
                    if (endName != name) {
                        throw XmlParsingException("Mismatched tag: expected ${name}, got ${endName}")
                    }
                    token = lexer.nextToken()
                    return (element, token)

                case XmlToken.EOF => return (element, token)
                case _ => 
                    token = lexer.nextToken()
            }
        }

        return (element, token)
    }

}