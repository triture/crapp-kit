package crapp.test.unit.token;

import crapp.token.CrappTokenSignedPayload;
import haxe.io.Bytes;
import utest.Assert;
import utest.Test;

class TestTokenSignedPayload extends Test {

    function test_if_generated_token_is_correct() {
        // ARRANGE
        var valueKey:String = "This is my secret key";
        var valuePayload:String = "This is the token Payload";
        var valueExpirationDate:Date = Date.fromString('2020-01-01 23:59:59');

        // ACT
        var token:CrappTokenSignedPayload = new CrappTokenSignedPayload();
        token.setData(valueExpirationDate, Bytes.ofString(valuePayload));

        var tokenString:String = token.generate(valueKey);

        // ASSERT
        Assert.same('SP AeQHAAEXOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkHU4uQvAgEqzVlR5515_8L7uwGZZ6F57-vhGb4W7txfA', tokenString);
    }

    function test_if_loaded_token_is_correct() {
        // ARRANGE
        var valueKey:String = "This is my secret key";
        var valueTokenString:String = 'SP AeQHAAIAOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkX9kwLVJEpQbEfd-815BIFVIZden_wNBMw55ivn1SOck';

        // ACT
        var token:CrappTokenSignedPayload = new CrappTokenSignedPayload();
        token.load(valueTokenString);

        // ASSERT
        Assert.same("This is the token Payload", token.payload.toString());

    }

    function test_if_wrong_signture_fail() {
        // ARRANGE
        var valueKey:String = "Wrong Key";
        var valueTokenString:String = 'SP AeQHAAEXOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkHU4uQvAgEqzVlR5515_8L7uwGZZ6F57-vhGb4W7txfA';
        var valueCurrDate:Date = Date.fromString('2020-01-02 00:00:00');

        var resultErrorMessage:String = '';
        var expectedErrorMessage:String = 'Invalid Signature';

        // ACT
        try {
            var token:CrappTokenSignedPayload = new CrappTokenSignedPayload();
            token.load(valueTokenString);
            token.validate(valueKey, valueCurrDate);
        } catch (e:Dynamic) {
            resultErrorMessage = Std.string(e);
        }

        // ASSERT
        Assert.equals(expectedErrorMessage, resultErrorMessage);
    }

    function test_if_token_is_expired() {
        // ARRANGE
        var valueKey:String = "This is my secret key";
        var valueTokenString:String = 'SP AeQHAAEXOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkHU4uQvAgEqzVlR5515_8L7uwGZZ6F57-vhGb4W7txfA';
        var valueCurrDate:Date = Date.fromString('2020-01-02 00:00:00');

        var resultErrorMessage:String = '';
        var expectedErrorMessage:String = 'Expired Token';

        // ACT
        try {
            var token:CrappTokenSignedPayload = new CrappTokenSignedPayload();
            token.load(valueTokenString);
            token.validate(valueKey, valueCurrDate);
        } catch (e:Dynamic) {
            resultErrorMessage = Std.string(e);
        }

        // ASSERT
        Assert.equals(expectedErrorMessage, resultErrorMessage);
    }

    function test_shortcut_validation() {
        // ARRANGE
        var valueKey:String = "This is my secret key";
        var valueTokenString:String = 'SP AeQHAAEXOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkHU4uQvAgEqzVlR5515_8L7uwGZZ6F57-vhGb4W7txfA';
        var valueCurrDate:Date = Date.fromString('2020-01-01 00:00:00');

        var result:Bool;
        var expectedResult:Bool = true;

        // ACT
        result = CrappTokenSignedPayload.isValid(valueTokenString, valueKey, valueCurrDate);

        // ASSERT
        Assert.same(expectedResult, result);
    }

    function test_shortcut_validation_expired_token() {
        // ARRANGE
        var valueKey:String = "This is my secret key";
        var valueTokenString:String = 'SP AeQHAAEXOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkHU4uQvAgEqzVlR5515_8L7uwGZZ6F57-vhGb4W7txfA';
        var valueCurrDate:Date = Date.fromString('2020-01-02 00:00:00');

        var result:Bool;
        var expectedResult:Bool = false;

        // ACT
        result = CrappTokenSignedPayload.isValid(valueTokenString, valueKey, valueCurrDate);

        // ASSERT
        Assert.same(expectedResult, result);
    }

    function test_shortcut_validation_not_valid_token() {
        // ARRANGE
        var valueKey:String = "wrong_key";
        var valueTokenString:String = 'SP AeQHAAEXOzsZAABUaGlzIGlzIHRoZSB0b2tlbiBQYXlsb2FkHU4uQvAgEqzVlR5515_8L7uwGZZ6F57-vhGb4W7txfA';
        var valueCurrDate:Date = Date.fromString('2020-01-01 00:00:00');

        var result:Bool;
        var expectedResult:Bool = false;

        // ACT
        result = CrappTokenSignedPayload.isValid(valueTokenString, valueKey, valueCurrDate);

        // ASSERT
        Assert.same(expectedResult, result);

    }

    function test_unable_to_read_invalid_token() {
        // ARRANGE
        var valueKey:String = "wrong_key";
        var valueTokenString:String = 'SP hjfekdfjks';
        var valueCurrDate:Date = Date.fromString('2020-01-02 00:00:00');

        var result:Bool;
        var expectedResult:Bool = false;

        // ACT
        result = CrappTokenSignedPayload.isValid(valueTokenString, valueKey, valueCurrDate);

        // ASSERT
        Assert.same(expectedResult, result);

    }


}
