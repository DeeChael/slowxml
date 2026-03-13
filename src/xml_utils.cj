package slowxml

import std.io.OutputStream

protected class StringOutputStream <: OutputStream & ToString {

    private let builder: StringBuilder = StringBuilder()

    public override func write(data: Array<Byte>): Unit {
        unsafe {
            this.builder.appendFromUtf8Unchecked(data)
        }
    }

    public override func flush(): Unit {
    }

    public override func toString(): String {
        return this.builder.toString()
    }

}