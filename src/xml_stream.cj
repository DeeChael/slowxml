package slowxml

import std.collection.*
import std.io.{OutputStream}

public open class XmlStreamWriter {

    private let output: OutputStream
    private var elementIndent: String = "  "
    private var depth: Int64 = 0
    private var currentElementOpen: Bool = false
    private var needsIndent: Bool = true
    private let elementStack: ArrayList<String> = ArrayList<String>()

    public static func string(): StringXmlStreamWriter {
        return StringXmlStreamWriter()
    }

    public static func of(output: OutputStream): XmlStreamWriter {
        return XmlStreamWriter(output)
    }

    public init(output: OutputStream) {
        this.output = output
    }

    public func writeDecl(version!: String = "1.0", encoding!: String = "UTF-8", standalone!: ?Bool = None): XmlStreamWriter {
        this.write("<?xml version=\"${version}\" encoding=\"${encoding}\"")
        if (let Some(stand) <- standalone) {
            this.write(" standalone=\"${if (stand) { "yes" } else { "no" }}\"")
        }
        this.write("?>\n")
        return this
    }

    public func writeDoctype(doctype: String): XmlStreamWriter {
        this.write("<!DOCTYPE ${doctype}>\n")
        return this
    }

    public func writeElementStart(name: String): XmlStreamWriter {
        if (currentElementOpen) {
            this.write(">")
            currentElementOpen = false
        }
        this.write("\n")
        this.write(_getIndent())
        this.write("<${name}")
        elementStack.add(name)
        currentElementOpen = true
        depth++
        needsIndent = false
        return this
    }

    public func writeAttribute(key: String, value: String): XmlStreamWriter {
        let escapedValue = escapeXmlText(value)
        this.write(" ${key}=\"${escapedValue}\"")
        return this
    }

    public func writeComment(content: String): XmlStreamWriter {
        if (currentElementOpen) {
            this.write(">")
            currentElementOpen = false
        }
        this.write("\n")
        this.write(_getIndent())
        this.write("<!-- ${content} -->")
        needsIndent = true
        return this
    }

    public func writeText(content: String): XmlStreamWriter {
        if (currentElementOpen) {
            this.write(">")
            currentElementOpen = false
        }
        let escapedContent = escapeXmlText(content)
        this.write(escapedContent)
        needsIndent = true
        return this
    }

    public func writeElementEnd(): XmlStreamWriter {
        if (elementStack.isEmpty()) {
            return this
        }
        let idx = elementStack.size - 1
        let name = elementStack[idx]
        elementStack.remove(idx..idx+1)
        depth--
        if (currentElementOpen) {
            this.write(" />\n")
            currentElementOpen = false
            needsIndent = true
        } else {
            this.write(_getIndent())
            this.write("</${name}>\n")
            needsIndent = true
        }
        return this
    }

    public func flush(): XmlStreamWriter {
        this.output.flush()
        return this
    }

    private func _getIndent(): String {
        var indent = ""
        for (i in 0..depth) {
            indent += elementIndent
        }
        return indent
    }

    private func write(data: String): Unit {
        unsafe {
            this.output.write(data.rawData())
        }
    }

}

public class StringXmlStreamWriter <: XmlStreamWriter {

    private let stringOutput: StringOutputStream = StringOutputStream()

    public init() {
        super(this.stringOutput)
    }

    public func build(): String {
        return this.stringOutput.toString()
    }

}
