package crapp.token;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import helper.kits.StringKit;
import haxe.crypto.Base64;
import haxe.io.Bytes;

class CrappTokenBearer extends CrappTokenBase {

    // MODEL
    // offset  0          1            9    1112131415     16
    // Bearer [version:1b][token_id:8b][yyyymmddhhmmss:7b][random_hex:64b] = 80 bytes

    public var version:Int;
    public var tokenId:Int;
    public var random:Bytes;
    public var expiresIn:Date;

    public function new() {
        super();

        this.version = 1;

        this.tokenId = 0;
        this.random = Bytes.alloc(0);
        this.expiresIn = Date.now();
    }

    public function load(token:String):Void {
        if (!StringTools.startsWith(token, 'Bearer ')) throw 'Token is not Bearer type';
        else {
            var tokenDataBase64:String = token.substr('Bearer '.length);
            var b:BytesInput = new BytesInput(Base64.urlDecode(tokenDataBase64));

            var version:Int = b.readByte();
            b.position = 0;

            switch (version) {
                case 1: this.loadVersion01(b);
                case _: throw 'Wrong Token Version';
            }
        }
    }

    private function loadVersion01(buf:BytesInput):Void {
        if (buf.length != 80) throw 'Wrong Token Size';

        this.version = buf.readByte();
        this.tokenId = Std.int(buf.readDouble());
        this.expiresIn = this.decodeDateFromBytes(buf);

        this.random = Bytes.alloc(64);
        for (pos in 0 ... 64) this.random.set(pos, buf.readByte());
    }

    public function setData(tokenId:Int, expiresIn:Date, ?random:Bytes):Void {
        this.tokenId = tokenId;
        this.random = random == null ? Bytes.ofHex(StringKit.generateRandomHex(64)) : random;
        this.expiresIn = expiresIn;
    }

    public function generate():String {
        var b:BytesOutput = new BytesOutput();

        b.writeByte(1); // version 1
        b.writeDouble(this.tokenId);

        this.encodeDateInBytes(this.expiresIn, b);

        for (pos in 0 ... this.random.length) {
            b.writeByte(this.random.get(pos));
        }

        return 'Bearer ' + Base64.urlEncode(b.getBytes());
    }

}
