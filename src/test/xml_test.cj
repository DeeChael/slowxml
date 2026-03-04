package slowxml.test

import slowxml.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func testHeaderAndComments() {
    let dirtyXml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE html>
    <App>
        <meta>data</meta>
        <content>Hello</content>
    </App>
    """
    let root = XmlParser(dirtyXml).parse().getOrThrow()
    
    @Expect(root.name, "App")
    @Expect(root.getElementsByTagName("content", recursive: false).size, 1)
    @Expect(root.getElementsByTagName("content")[0].innerText, "Hello")
}

@Test
func testMixedContent() {
    let mixedXml = "<root>TextA<child/>TextB</root>"
    let root = XmlParser(mixedXml).parse().getOrThrow()
    
    @Expect(root.children.size, 3)
    @Expect(root.children[0] is XmlTextNode, true)
    @Expect(root.children[1] is XmlElementNode, true)
    @Expect(root.children[2] is XmlTextNode, true)
    @Expect(root.innerText, "TextATextB")
}