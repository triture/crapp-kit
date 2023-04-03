package crapp.test.unit.multimap;

import tricks.multimap.N2NMap;
import utest.Assert;
import utest.Test;

class N2NMapTest extends Test {

    function test_get_keys_from_value() {
        // ARRANGE
        var k1:TestKey = {k:'K1'};
        var k2:TestKey = {k:'K2'};
        var v1:TestValue = {v:'v1'};
        var v2:TestValue = {v:'v2'};
        var v3:TestValue = {v:'v3'};

        var map:N2NMap<TestKey, TestValue> = new N2NMap<TestKey, TestValue>();
        map.add(k1, v1);
        map.add(k1, v2);
        map.add(k2, v2);
        map.add(k2, v3);

        var result:Array<TestKey>;
        var expected:Array<TestKey> = [k1, k2];

        // ACT
        result = map.getKeys(v2);

        // ASSERT
        Assert.same(expected, result);
    }

    function test_get_values_from_key() {
        // ARRANGE
        var k1:TestKey = {k:'K1'};
        var k2:TestKey = {k:'K2'};
        var v1:TestValue = {v:'v1'};
        var v2:TestValue = {v:'v2'};
        var v3:TestValue = {v:'v3'};

        var map:N2NMap<TestKey, TestValue> = new N2NMap<TestKey, TestValue>();
        map.add(k1, v1);
        map.add(k1, v2);
        map.add(k2, v2);
        map.add(k2, v3);

        var result:Array<TestValue>;
        var expected:Array<TestValue> = [v1, v2];

        // ACT
        result = map.getValues(k1);

        // ASSERT
        Assert.same(expected, result);
    }

    function test_remove_values() {
        // ARRANGE
        var k1:TestKey = {k:'K1'};
        var k2:TestKey = {k:'K2'};
        var v1:TestValue = {v:'v1'};
        var v2:TestValue = {v:'v2'};
        var v3:TestValue = {v:'v3'};

        var map:N2NMap<TestKey, TestValue> = new N2NMap<TestKey, TestValue>();
        map.add(k1, v1);
        map.add(k1, v2);
        map.add(k2, v2);
        map.add(k2, v3);

        var result:Array<TestKey>;
        var expected:Array<TestKey> = [];

        // ACT
        map.removeValue(k1, v2);
        map.removeValue(k2, v2);

        result = map.getKeys(v2);

        // ASSERT
        Assert.same(expected, result);
    }

    function test_get_unique_keys_and_unique_values() {
        // ARRANGE
        var k1:TestKey = {k:'K1'};
        var k2:TestKey = {k:'K2'};
        var v1:TestValue = {v:'v1'};
        var v2:TestValue = {v:'v2'};
        var v3:TestValue = {v:'v3'};

        var map:N2NMap<TestKey, TestValue> = new N2NMap<TestKey, TestValue>();
        map.add(k1, v1);
        map.add(k1, v2);
        map.add(k2, v2);
        map.add(k2, v3);

        var resultKeys:Array<TestKey>;
        var resultValues:Array<TestValue>;

        var expectedKeys:Array<TestKey> = [k1, k2];
        var expectedValues:Array<TestValue> = [v1, v2, v3];

        // ACT
        resultKeys = map.uniqueKeys();
        resultValues = map.uniqueValues();

        // ASSERT
        Assert.same(expectedKeys, resultKeys);
        Assert.same(expectedValues, resultValues);
    }

}

private typedef TestKey = {
    var k:String;
}

private typedef TestValue = {
    var v:String;
}
