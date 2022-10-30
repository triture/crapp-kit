package crapp.db;

import node.mysql.Mysql.MysqlResultSet;

typedef DatabaseSuccess<T> = {
    var length:Int;
    var raw:MysqlResultSet<T>;
}
