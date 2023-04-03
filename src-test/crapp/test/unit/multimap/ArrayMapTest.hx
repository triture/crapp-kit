package crapp.test.unit.multimap;

import utest.Assert;
import tricks.multimap.ArrayMap;
import utest.Test;

class ArrayMapTest extends Test {


    function test_add_an_content_and_retrieve() {
        // ARRANGE
        var map:ArrayMap<{name:String}, {value:Int}> = new ArrayMap<{name:String}, {value:Int}>();
        var valueOdd1:{value:Int} = {value:1};
        var valueKeyOdd:{name:String} = {name:'ODD'};
        var resultValue:Array<{value:Int}>;
        var expectedValue:Array<{value:Int}> = [valueOdd1];

        // ACT
        map.add(valueKeyOdd, valueOdd1);
        resultValue = map.getValues(valueKeyOdd);

        // ASSERT
        Assert.same(expectedValue, resultValue);
    }

    function test_add_two_elementss_and_retrieve() {
        // ARRANGE
        var map:ArrayMap<{name:String}, {value:Int}> = new ArrayMap<{name:String}, {value:Int}>();
        var valueOdd1:{value:Int} = {value:1};
        var valueOdd3:{value:Int} = {value:3};
        var valueKeyOdd:{name:String} = {name:'ODD'};
        var resultValue:Array<{value:Int}>;
        var expectedValue:Array<{value:Int}> = [valueOdd1, valueOdd3];

        // ACT
        map.add(valueKeyOdd, valueOdd1);
        map.add(valueKeyOdd, valueOdd3);

        resultValue = map.getValues(valueKeyOdd);

        // ASSERT
        Assert.same(expectedValue, resultValue);
    }

    function test_two_keys_with_two_elements_each_and_retrieve() {
        // ARRANGE
        var map:ArrayMap<{name:String}, {value:Int}> = new ArrayMap<{name:String}, {value:Int}>();
        var valueOdd1:{value:Int} = {value:1};
        var valueEven2:{value:Int} = {value:2};
        var valueOdd3:{value:Int} = {value:3};
        var valueEven4:{value:Int} = {value:4};
        var valueKeyOdd:{name:String} = {name:'ODD'};
        var valueKeyEven:{name:String} = {name:'EVEN'};
        var resultValue:Array<{value:Int}>;
        var expectedValue:Array<{value:Int}> = [valueEven2, valueEven4];

        // ACT
        map.add(valueKeyOdd, valueOdd1);
        map.add(valueKeyEven, valueEven2);
        map.add(valueKeyOdd, valueOdd3);
        map.add(valueKeyEven, valueEven4);

        resultValue = map.getValues(valueKeyEven);

        // ASSERT
        Assert.same(expectedValue, resultValue);
    }

    function test_add_duplicated_element_must_be_discarted() {
        // ARRANGE
        var map:ArrayMap<{name:String}, {value:Int}> = new ArrayMap<{name:String}, {value:Int}>();
        var valueOdd1:{value:Int} = {value:1};
        var valueOdd3:{value:Int} = {value:3};
        var valueKeyOdd:{name:String} = {name:'ODD'};
        var resultValue:Array<{value:Int}>;
        var expectedValue:Array<{value:Int}> = [valueOdd1, valueOdd3];

        // ACT
        map.add(valueKeyOdd, valueOdd1);
        map.add(valueKeyOdd, valueOdd1);
        map.add(valueKeyOdd, valueOdd3);

        resultValue = map.getValues(valueKeyOdd);

        // ASSERT
        Assert.same(expectedValue, resultValue);
    }

    function test_add_and_remove_elements() {
        // ARRANGE
        var map:ArrayMap<{name:String}, {value:Int}> = new ArrayMap<{name:String}, {value:Int}>();
        var valueOdd1:{value:Int} = {value:1};
        var valueOdd3:{value:Int} = {value:3};
        var valueKeyOdd:{name:String} = {name:'ODD'};
        var resultValue:Array<{value:Int}>;
        var expectedValue:Array<{value:Int}> = [valueOdd3];

        // ACT
        map.add(valueKeyOdd, valueOdd1);
        map.add(valueKeyOdd, valueOdd3);

        map.removeValue(valueKeyOdd, valueOdd1);

        resultValue = map.getValues(valueKeyOdd);

        // ASSERT
        Assert.same(expectedValue, resultValue);
    }


    function test_key_should_not_exists_when_removed_all_elements() {
        // ARRANGE
        var map:ArrayMap<{name:String}, {value:Int}> = new ArrayMap<{name:String}, {value:Int}>();
        var valueOdd1:{value:Int} = {value:1};
        var valueOdd3:{value:Int} = {value:3};
        var valueKeyOdd:{name:String} = {name:'ODD'};

        var resultExists:Bool;
        var expectedExists:Bool = false;

        // ACT
        map.add(valueKeyOdd, valueOdd1);
        map.add(valueKeyOdd, valueOdd3);

        map.removeValue(valueKeyOdd, valueOdd1);
        map.removeValue(valueKeyOdd, valueOdd3);

        resultExists = map.exists(valueKeyOdd);

        // ASSERT
        Assert.same(expectedExists, resultExists);
    }

    function test_get_all_keys_created() {
        // ARRANGE
        var map:ArrayMap<{name:String}, {value:Int}> = new ArrayMap<{name:String}, {value:Int}>();
        var valueOdd1:{value:Int} = {value:1};
        var valueEven2:{value:Int} = {value:2};
        var valueOdd3:{value:Int} = {value:3};
        var valueEven4:{value:Int} = {value:4};

        var valueKeyOdd:{name:String} = {name:'ODD'};
        var valueKeyEven:{name:String} = {name:'EVEN'};

        var resultValue:Array<{name:String}>;
        var expectedValue:Array<{name:String}> = [valueKeyOdd, valueKeyEven];

        // ACT
        map.add(valueKeyOdd, valueOdd1);
        map.add(valueKeyEven, valueEven2);
        map.add(valueKeyOdd, valueOdd3);
        map.add(valueKeyEven, valueEven4);

        resultValue = map.keys();

        // ASSERT
        Assert.same(expectedValue, resultValue);
    }

}
