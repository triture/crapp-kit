package crapp.test.integration;

import crapp.test.integration.databasepool.TestDatabasePool;

class CrappKitIntegrationTest {

    static public function main() {

        utest.UTest.run([
            new TestDatabasePool()
        ]);

    }

}
