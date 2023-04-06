package crapp.test.unit.crapp.token;

import utest.Assert;
import anonstruct.AnonStruct;
import crapp.token.CrappTokenManager;
import utest.Test;

class TestTokenManager extends Test {

    function test_create_and_validate_token() {
        // ARRANGE
        var manager:CrappTokenManager<{data:String}>;
        var tokenType:String = 'test';
        var payload:{data:String} = {data:'hello'};
        var salt:String = '123';
        var resultToken:String;
        var lifetime:Int = 1;
        var keyCreator = (payload:{data:String}, salt:String) -> {
            var key:String = salt + payload.data;
            return key;
        }

        var valueGeneratedToken:String;
        var expectedIsValidToken:Bool = true;
        var resultIsValidToken:Bool;

        // ACT
        manager = new CrappTokenManager<{data:String}>(
            tokenType,
            lifetime,
            TestTokenManagerValidator,
            keyCreator
        );

        resultToken = manager.createToken(payload, salt);
        resultIsValidToken = manager.validateToken(resultToken, salt);

        // ASSERT
        Assert.equals(expectedIsValidToken, resultIsValidToken);
    }

}

private class TestTokenManagerValidator extends AnonStruct {

    public function new() {
        super();

        this.propertyString('data')
            .refuseEmpty()
            .refuseEmpty();

    }
}