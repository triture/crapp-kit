package crapp.token;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;

class CrappTokenBase {

    public function new() {

    }

    inline private function decodeDateFromBytes(b:BytesInput):Date {
        return new Date(
            b.readUInt16(),
            b.readByte(),
            b.readByte(),
            b.readByte(),
            b.readByte(),
            b.readByte()
        );
    }

    inline private function encodeDateInBytes(date:Date, b:BytesOutput):Void {
        b.writeUInt16(date.getFullYear());
        b.writeByte(date.getMonth());
        b.writeByte(date.getDate());
        b.writeByte(date.getHours());
        b.writeByte(date.getMinutes());
        b.writeByte(date.getSeconds());
    }
}
