package crapp.test.unit.crapp.service.reqres;

import utest.Assert;
import haxe.ds.StringMap;
import crapp.service.reqres.CrappParameterType;
import utest.Test;

class TestCrappParameterType extends Test {

    function test_route_without_parameter_should_count_zero_keys() {
        // ARRANGE
        var route:String = '/hello/world';
        var result:StringMap<CrappParameterType>;
        var resultKeyCount:Int;
        var expectedKeyCount:Int = 0;

        // ACT
        result = CrappParameterType.GET_ROUTE_PARAMETERS(route);
        resultKeyCount = 0;
        for (key in result.keys()) resultKeyCount++;

        // ASSERT
        Assert.equals(expectedKeyCount, resultKeyCount);
    }

    function test_route_without_two_parameter_should_count_two_keys() {
        // ARRANGE
        var route:String = '/hello/[name:String]/[age:Int]';
        var result:StringMap<CrappParameterType>;
        var resultKeyCount:Int;
        var expectedKeyCount:Int = 2;

        // ACT
        result = CrappParameterType.GET_ROUTE_PARAMETERS(route);
        resultKeyCount = 0;
        for (key in result.keys()) resultKeyCount++;

        // ASSERT
        Assert.equals(expectedKeyCount, resultKeyCount);
    }

    function test_route_with_wrong_type_should_not_be_interpreted_as_parameter() {
        // ARRANGE
        var route:String = '/hello/[name:Other]/[age:Int]';
        var result:StringMap<CrappParameterType>;
        var resultKeyCount:Int;
        var expectedKeyCount:Int = 1;

        // ACT
        result = CrappParameterType.GET_ROUTE_PARAMETERS(route);
        resultKeyCount = 0;
        for (key in result.keys()) resultKeyCount++;

        // ASSERT
        Assert.equals(expectedKeyCount, resultKeyCount);
    }

    function test_route_parameters_should_be_identified_with_the_correct_type() {
        // ARRANGE
        var route:String = '/hello/[name:String]/[age:Int]';
        var result:StringMap<CrappParameterType>;

        // ACT
        result = CrappParameterType.GET_ROUTE_PARAMETERS(route);

        // ASSERT
        Assert.equals(true, result.exists('name'));
        Assert.equals(CrappParameterType.STRING, result.get('name'));

        Assert.equals(true, result.exists('age'));
        Assert.equals(CrappParameterType.INT, result.get('age'));
    }

    function test_route_must_be_converted_to_a_clean_route_with_default_converter() {
        // ARRANGE
        var route:String = '/hello/[name:String]/[age:Int]';
        var result:String;
        var expectedResult:String = '/hello/:name/:age';

        // ACT
        result = CrappParameterType.GET_CLEAN_ROUTE(route);

        // ASSERT
        Assert.equals(expectedResult, result);
    }

    function test_route_must_be_converted_to_a_clean_route_with_other_converter() {
        // ARRANGE
        var route:String = '/hello/[name:String]/[age:Int]';
        var result:String;
        var expectedResult:String = '/hello/{s_name}/{i_age}';

        var converter = function(param:String, type:String):String {
            return '{${type.toLowerCase().charAt(0)}_${param}}';
        }

        // ACT
        result = CrappParameterType.GET_CLEAN_ROUTE(route, converter);

        // ASSERT
        Assert.equals(expectedResult, result);
    }

}
