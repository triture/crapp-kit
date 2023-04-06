package crapp.token;

import haxe.io.Bytes;
import helper.kits.DateKit;
import anonstruct.AnonStruct;
import haxe.crypto.Sha256;

class CrappTokenManager<PAYLOAD> {

    private var tokenType:String;
    private var privateKey:String;
    private var keyCreator:(data:PAYLOAD, salt:String)->String;
    private var validator:Class<AnonStruct>;
    private var lifetimeMinutes:Int;

    public function new(tokenType:String, lifetimeMinutes:Int, validator:Class<AnonStruct>, keyCreator:(data:PAYLOAD, salt:String)->String) {
        this.tokenType = tokenType;
        this.lifetimeMinutes = lifetimeMinutes;
        this.validator = validator;
        this.keyCreator = keyCreator;

        this.startupToken();
    }

    public function validateToken(tokenValue:String, salt:String):Bool {
        try {
            var token:CrappTokenSignedPayload = new CrappTokenSignedPayload();
            token.load(tokenValue);

            var payload:PAYLOAD = haxe.Json.parse(token.payload.toString());
            var validator:AnonStruct = Type.createInstance(this.validator, []);
            validator.validate(payload);

            var key:String = this.generateKey(payload, salt);
            token.validate(key, Date.now());

            return true;
        } catch (e:Dynamic) {}

        return false;
    }

    public function createToken(payload:PAYLOAD, salt:String):Null<String> {
        try {
            var validator:AnonStruct = Type.createInstance(this.validator, []);
            validator.validate(payload);
        } catch (e:Dynamic) {
            return null;
        }

        var key:String = this.generateKey(payload, salt);
        var expires:Date = DateKit.addMinutes(Date.now(), this.lifetimeMinutes);
        var payloadBytes:Bytes = Bytes.ofString(haxe.Json.stringify(payload));

        var token:CrappTokenSignedPayload = new CrappTokenSignedPayload();
        token.setData(expires, payloadBytes);

        return token.generate(key);
    }

    private function generateKey(payload:PAYLOAD, salt:String):String {
        var key1:String = this.keyCreator(payload, salt);
        var key2:String = '${this.tokenType}.${this.privateKey}';
        var result:String = Sha256.encode(key1 + key2);

        return result;
    }

    private function startupToken():Void {
        var privateKey:String = this.getEnv('CRAPP_PRIVATE_KEY');
        var rounds:Int = Std.parseInt(this.getEnv('CRAPP_ROUNDS'));

        if (rounds == null) rounds = 0;

        for (i in 0 ... rounds) privateKey = Sha256.encode(privateKey);

        this.privateKey = privateKey;
    }

    private function getEnv(key:String):String {
        var value:String = Sys.getEnv(key);
        if (value == null) return '';
        return value;
    }

}
