package crapp.test.token;

import haxe.io.Bytes;
import utest.Test;
import utest.Assert;
import crapp.token.CrappTokenBearer;

class TestTokenBearerLoader extends Test {

    private var tokenCreator:CrappTokenBearer;
    private var tokenLoader:CrappTokenBearer;
    private var tokenId:Int;
    private var tokenExpiration:Date;
    private var random:Bytes;

    function test_if_loaded_token_is_correct() {
        // ARRANGE
        this.tokenId = 3429;
        this.tokenExpiration = Date.fromString('2020-01-01 24:59:59');
        this.random = Bytes.ofHex('bd8f76e8af39c4e1def938ae05c24c1c10d9db147b825f644c68c427a021bf68332b0b5bb9188a10b74c124f711564f09998149192e6fc3f81726bfe8291b83e');

        this.tokenCreator = new CrappTokenBearer();
        this.tokenCreator.setData(this.tokenId, this.tokenExpiration, this.random);

        var tokenString:String = this.tokenCreator.generate();

        // ACT
        this.tokenLoader = new CrappTokenBearer();
        this.tokenLoader.load(tokenString);

        // ASSERT
        Assert.same(3429, this.tokenLoader.tokenId);
        Assert.same(Date.fromString('2020-01-01 24:59:59'), this.tokenLoader.expiresIn);
        Assert.same('bd8f76e8af39c4e1def938ae05c24c1c10d9db147b825f644c68c427a021bf68332b0b5bb9188a10b74c124f711564f09998149192e6fc3f81726bfe8291b83e', this.tokenLoader.random.toHex());

    }

    function test_loading_invalid_token() {
        // arrange
        this.tokenCreator = new CrappTokenBearer();

        Assert.raises(this.tokenCreator.load.bind('Bearer AsddfhdjdsDShsdfjdSAdjiddas'));
    }
}
