package slowxml

public enum XmlToken {
    | StartTag(String)
    | EndTag(String)
    | AttrName(String)
    | AttrValue(String)
    | Text(String)
    | Skipable
    | SelfClosing
    | TagEnd
    | EOF
    | Error(String)
}