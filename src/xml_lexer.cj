package slowxml

import std.unicode.*

public class XmlLexer {

    private let input: Array<Rune>
    private let length: Int64
    
    private var pos: Int64 = 0
    private var isInTag: Bool = false

    public init(content: String) {
        this.input = content.toRuneArray()
        this.length = Int64(input.size)
    }

    private func isEOF(): Bool {
        pos >= length
    }

    private func peek(): Rune {
        if (isEOF()) {
            return r'\u{0000}'
        }
        input[pos]
    }

    private func consume(): Rune {
        let res = peek();
        pos++;
        res
    }

    public func nextToken(): XmlToken {
        if (isEOF()) {
            return XmlToken.EOF
        }

        if (!isInTag) {
            if (peek() == r'<') {
                consume()
                let nextC = peek()

                if (nextC == r'?') {
                    consume()
                    readUntil(r"?")
                    if (peek() != r">") {
                        return XmlToken.Error("Expect '>'")
                    }
                    consume()
                    isInTag = false
                    return XmlToken.Skipable
                }

                if (nextC == r'!') {
                    consume()
                    if (peek() == r'-') {
                            isInTag = false
                            return XmlToken.Skipable

                    }
                    readUntil(r">")
                    isInTag = false
                    return XmlToken.Skipable
                }

                isInTag = true
                if (peek() == r'/') {
                    consume()
                    return XmlToken.EndTag(readIdentifier())
                }
                return XmlToken.StartTag(readIdentifier())
            } else {
                return XmlToken.Text(readTextContent())
            }
        }

        skipWhitespace()
        let c = peek()

        if (c == r'>') {
            isInTag = false
            consume()
            return XmlToken.TagEnd
        }

        if (c == r'/') {
            consume()
            if (peek() == r'>') {
                isInTag = false
                consume()
                return XmlToken.SelfClosing
            }
            return XmlToken.Error("Unexpected '/'")
        }

        if (c == r'=') {
            consume()
            return nextToken()
        }

        if (c == r'"' || c == r'\'') {
            let quoted = consume()
            let value = readUntil(quoted)
            return XmlToken.AttrValue(value)
        }

        if (isXmlIdentifierStart(c)) {
            return XmlToken.AttrName(readIdentifier())
        }

        let unknown = consume()
        return XmlToken.Error("Unknown char in tag: ${unknown}")
    }

    private func readIdentifier(): String {
        let sb = StringBuilder()
        while (!isEOF() && isXmlIdentifierPart(peek())) {
            sb.append(consume())
        }
        return sb.toString()
    }

    private func readTextContent(): String {
        let sb = StringBuilder()
        while (!isEOF() && peek() != r'<') {
            sb.append(consume())
        }
        return sb.toString()
    }

    private func readUntil(target: Rune): String {
        let sb = StringBuilder()
        while (!isEOF() && peek() != target) {
            sb.append(consume())
        }
        if (!isEOF()) {
            consume()
        }
        return sb.toString()
    }

    private func skipWhitespace() {
        while (!isEOF() && (peek() == r' ' || peek() == r'\n' || peek() == r'\r' || peek() == r'\t')) {
            consume()
        }
    }

    private func isXmlIdentifierStart(c: Rune): Bool {
        c.isLetter() || c == r'_' || c == r':'
    }
    
    private func isXmlIdentifierPart(c: Rune): Bool {
        c.isLetter() || c.isNumber() || c == r'_' || c == r'-' || c == r':' || c == r'.'
    }

}
