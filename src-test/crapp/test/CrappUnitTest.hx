package crapp.test;

import crapp.test.token.TestTokenSignedPayload;
import crapp.test.token.TestTokenBearerLoader;

class CrappUnitTest {

    static public function main() {

        utest.UTest.run([
            new TestTokenBearerLoader(),
            new TestTokenSignedPayload()
        ]);

    }

}
