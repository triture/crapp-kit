package crapp.test.unit.token;

import crapp.token.CrappTokenSignedPayload;
import haxe.io.Bytes;
import utest.Assert;
import utest.Test;

class TestTokenSignedPayload extends Test {

    function test_if_generated_token_is_correct() {
        // ARRANGE
        var key:String = "This is my secret key";
        var payload:String = "This is the token Payload";
        var expiration:Date = Date.fromString('2020-01-01 24:59:59');

        // ACT
        var token:CrappTokenSignedPayload = new CrappTokenSignedPayload(key);
        token.setData(expiration, Bytes.ofString(payload));

        var tokenString:String = token.generate();

        // ASSERT
        Assert.same('SP AeQHAAIAOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkX9kwLVJEpQbEfd-815BIFVIZden_wNBMw55ivn1SOck', tokenString);
    }

    function test_if_loaded_token_is_correct() {
        // ARRANGE
        var key:String = "This is my secret key";
        var tokenString:String = 'SP AeQHAAIAOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkX9kwLVJEpQbEfd-815BIFVIZden_wNBMw55ivn1SOck';

        // ACT
        var token:CrappTokenSignedPayload = new CrappTokenSignedPayload(key);
        token.load(tokenString);

        // ASSERT
        Assert.same("This is the token Payload", token.payload.toString());
    }

    function test_if_wrong_signture_fail() {
        // ARRANGE
        var key:String = "Wrong Key";
        var tokenString:String = 'SP AeQHAAIAOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkX9kwLVJEpQbEfd-815BIFVIZden_wNBMw55ivn1SOck';

        // ACT
        var token:CrappTokenSignedPayload = new CrappTokenSignedPayload(key);

        // ASSERT
        Assert.raises(token.load.bind(tokenString));
    }

}
