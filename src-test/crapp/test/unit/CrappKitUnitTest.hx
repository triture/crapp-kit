package crapp.test.unit;

import crapp.test.unit.crapp.token.TestTokenManager;
import crapp.test.unit.multimap.N2NMapTest;
import crapp.test.unit.multimap.ArrayMapTest;
import crapp.test.unit.sessioncounter.SessionCounterTest;
import crapp.test.unit.cacheback.CacheBackServerTest;
import crapp.test.unit.crapp.service.reqres.TestCrappParameterType;
import crapp.test.unit.doevent.DoEventDispatcherTest;
import crapp.test.unit.token.TestTokenSignedPayload;
import crapp.test.unit.token.TestTokenBearerLoader;

class CrappKitUnitTest {

    static public function main() {

        utest.UTest.run([
            new TestTokenBearerLoader(),
            new TestTokenSignedPayload(),

            new DoEventDispatcherTest(),

            new TestCrappParameterType(),
            new CacheBackServerTest(),
            new SessionCounterTest(),
            new ArrayMapTest(),
            new N2NMapTest(),

            new TestTokenManager()
        ]);

    }

}
