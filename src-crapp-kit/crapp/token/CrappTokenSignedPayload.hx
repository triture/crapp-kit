package crapp.token;

import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.crypto.Sha256;

class CrappTokenSignedPayload extends CrappTokenBase {

    // MODEL
    // offset  0
    //      SP [version:1b][yyyymmddhhmmss:7b][payload_length:3b][payload:nb][signature:32b]

    private var key:String;

    public var version:Int;
    public var payload:Bytes;
    public var expiresIn:Date;

    public function new(key:String) {
        super();

        this.key = key;
        this.version = 1;
    }

    public function setData(expiresIn:Date, payload:Bytes):Void {
        this.expiresIn = expiresIn;
        this.payload = payload;
    }

    public function load(token:String):Void {
        if (!StringTools.startsWith(token, 'SP ')) throw 'Token is not Signed Payload type';
        else {
            var tokenDataBase64:String = token.substr('SP '.length);
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
        this.version = buf.readByte();
        this.expiresIn = this.decodeDateFromBytes(buf);

        var payloadLength:Int = buf.readUInt24();
        this.payload = buf.read(payloadLength);


        var signature:Bytes = buf.readAll();
        if (signature.compare(this.generateSignature()) != 0) throw "Invalid Signature";
    }

    private function generateSignature():Bytes {
        var keyBytes:Bytes = Sha256.make(Bytes.ofString(this.key));
        var k1:Bytes = Sha256.make(keyBytes);
        var k2:Bytes = Sha256.make(k1);

        var dataToSign:BytesOutput = new BytesOutput();
        dataToSign.write(k2);
        dataToSign.writeByte(this.version);
        dataToSign.write(Bytes.ofString(DateTools.format(this.expiresIn, "%Y-%m-%d %H:%M:%S")));
        dataToSign.write(this.payload);

        var k3:Bytes = Sha256.make(dataToSign.getBytes());

        var finalData:BytesOutput = new BytesOutput();
        finalData.write(k1);
        finalData.write(k3);

        return Sha256.make(finalData.getBytes());
    }

    public function generate():String {
        var b:BytesOutput = new BytesOutput();

        b.writeByte(1); // version 1

        this.encodeDateInBytes(this.expiresIn, b);

        b.writeUInt24(this.payload.length);
        b.write(this.payload);
        b.write(this.generateSignature());

        return 'SP ' + Base64.urlEncode(b.getBytes());
    }
}
