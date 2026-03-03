package slowxml

import std.collection.*

public class XmlParser {

    private let lexer: XmlLexer
    
    private var currentToken: XmlToken = EOF

    public init(xml: String) {
        this.lexer = XmlLexer(xml)
        this.currentToken = lexer.nextToken()
    }

    private func nextToken() {
        this.currentToken = lexer.nextToken()
    }

    public func parse(): ?XmlElementNode {
        while (true) {
            match (currentToken) {
                case StartTag(name) => return parseElement(name)
                case EOF => return None
                case Error(message) => return None
                case _ => this.currentToken = lexer.nextToken()
            }
        }
        return None
    }

    private func parseElement(name: String): ?XmlElementNode {
        let element = XmlElementNode(name)
        nextToken()

        while (true) {
            match (currentToken) {
                case XmlToken.AttrName(key) =>
                    nextToken()
                    match (currentToken) {
                        case XmlToken.AttrValue(value) => 
                            element.attributes[key] = value
                            nextToken()
                        case _ => throw XmlParsingException("Expected attribute value")
                    }
                case XmlToken.TagEnd => 
                    nextToken()
                    break
                case XmlToken.SelfClosing => 
                    nextToken()
                    return element
                case _ => break
            }
        }

        while (true) {
            match (currentToken) {
                case XmlToken.Text(content) =>
                    if (content.trimAscii().size > 0) {
                        element.children.add(XmlTextNode(content))
                    }
                    nextToken()

                case XmlToken.StartTag(childName) =>
                    element.children.add(parseElement(childName).getOrThrow {  => XmlParsingException("Parsing error") })

                case XmlToken.EndTag(endName) =>
                    if (endName != name) {
                        throw XmlParsingException("Mismatched tag: expected ${name}, got ${endName}")
                    }
                    nextToken()
                    return element

                case XmlToken.EOF => return element
                case _ => nextToken()
            }
        }

        return None
    }

}