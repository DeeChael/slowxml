package slowxml

public func xml(name: String, block: (XmlElementNode) -> Unit): XmlElementNode {
    let root = XmlElementNode(name)
    block(root)
    return root
}

extend XmlElementNode {
    
    public func node(name: String, block: (XmlElementNode) -> Unit): XmlElementNode {
        let child = XmlElementNode(name)
        this.children.add(child)
        block(child)
        return child
    }

    public func text(content: String): Unit {
        this.children.add(XmlTextNode(content))
    }

}