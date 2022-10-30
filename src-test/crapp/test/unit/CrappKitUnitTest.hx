package crapp.test.unit;

import crapp.test.unit.doevent.DoEventDispatcherTest;
import crapp.test.unit.token.TestTokenSignedPayload;
import crapp.test.unit.token.TestTokenBearerLoader;

class CrappKitUnitTest {

    static public function main() {

        utest.UTest.run([
            new TestTokenBearerLoader(),
            new TestTokenSignedPayload(),

            new DoEventDispatcherTest()
        ]);

    }

}
