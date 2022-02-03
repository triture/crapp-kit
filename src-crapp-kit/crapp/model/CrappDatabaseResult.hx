package crapp.model;

import node.mysql.Mysql;

typedef CrappDatabaseResult<T> = {
    var hasError:Bool;
    var errorMessage:String;
    var errorCode:String;
    var hasCreatedSomething:Bool;
    var createdId:Int;
    var length:Int;
    var result:MysqlResultSet<T>;
}