package crapp.test.integration.base;

import helper.kits.StringKit;
import crapp.db.DatabasePool;
import crapp.model.CrappModel.CrappModelDatabase;

import utest.Test;

class TestIntegrationBase extends Test {

    private var databaseModel:CrappModelDatabase;
    private var pool:DatabasePool;
    private var testTable:String;

    function setup() {
        this.testTable = 'test_${StringKit.generateRandomHex(6)}';

        this.databaseModel = {
            host : 'mysql',
            user : 'root',
            password : '',
            port : 3306,
            max_connections : 3,
            acquire_timeout : 150
        }

        this.pool = new DatabasePool(this.databaseModel);
    }

    function teardown() {
        this.pool.close();
    }

}
