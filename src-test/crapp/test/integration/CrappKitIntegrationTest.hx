package crapp.test.integration;

import crapp.test.integration.controller.database.TestDatabaseController;

class CrappKitIntegrationTest {

    static public function main() {

        utest.UTest.run([
            new TestDatabaseController()
        ]);

    }

}
