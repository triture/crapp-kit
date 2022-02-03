package crapp.token;

import haxe.io.Bytes;

class CrappTokenTypedSignedPayload<T> extends CrappTokenSignedPayload {

    public var data:T;

    public function setTypedData(expiresIn:Date, payload:T):Void this.setData(expiresIn, Bytes.ofString(haxe.Json.stringify(payload)));

    override public function load(token:String):Void {
        super.load(token);
        this.data = haxe.Json.parse(this.payload.toString());
    }

}
