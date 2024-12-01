import 'package:dart_server_plus/dart_server_plus.dart';


part 'builders/query_builder.dart';
part 'builders/transactions.dart';
part 'builders/select_query_builder.dart';
part 'builders/insert_query_builder.dart';
part 'builders/update_query_builder.dart';
part 'builders/delete_query_builder.dart';

class DartServerPlus {
  DartServerPlus({required this.client, required List<Schema> schemas, this.logging = false}) {
    _transactions = Transactions(client: client, logging: logging);
    for (Schema s in schemas) {
      if (s.fields.isEmpty) throw "Atleast one field is required with ${s.table} Table";
      _schemas[s.table] = s;
    }
  }

  final DatabaseClient client;
  final Map<String, Schema> _schemas = {};
  final bool logging;
  late Transactions _transactions;

  Transactions get transactions => _transactions;

  Future<Object> rawQuery(String query) async {
    if (logging) print("Executing: $query");
    return await client.executeResult(query);
  }

  Future<void> sync({bool syncTable = false}) async {
    if (syncTable) {
      await client.execute("""
  DO \$\$
  DECLARE
      r RECORD;
  BEGIN
      FOR r IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') LOOP
          EXECUTE 'DROP TABLE IF EXISTS ' || r.table_name || ' CASCADE;';
      END LOOP;
  END \$\$;
""");
    }
    for (Schema s in _schemas.values) {
      if (s.fields.isEmpty) throw "Atleast one field is required with ${s.table} Table";
      List<String> fields = [];
      s.fields.forEach((key, value) {
        if (value is DataType) {
          fields.add("$key ${value.value}");
        } else if (value is Map) {
          if (value['type'] == null) {
            throw "Datatype is missing for $key";
          } else if (value['type'] is! DataType) {
            throw "invalid data type of $key : ${value['type']}";
          }
          DataType dataType = value['type'];
          String column = "$key ${dataType.value}";
          if (value['primaryKey'] == true) {
            column += " PRIMARY KEY";
          }
          if (value['autoIncrement'] == true) {
            column += " AUTOINCREMENT";
          }
          if (value['allowNull'] == false) {
            column += " NOT NULL";
          }

          if (value['default'] != null) {
            column += " DEFAULT ${value['default']}";
          }

          if (value['unique'] == true) {
            column += " UNIQUE";
          }

          if (value['reference'] != null) {
            if (value['reference'] is! Map || value['reference']['table'] == null || value['reference']['column'] == null) throw "invalid reference for $key";
            column += " REFERENCES ${value['reference']['table']}(${value['reference']['column']})";
            if (value['cascase'] == true) {
              column += " ON DELETE CASCADE";
            }
            if (value['restrict'] == true) {
              column += " ON DELETE RESTRICT";
            }
            if (value['setNull'] == true) {
              column += " ON DELETE SET NULL";
            }
          }
          fields.add(column);
        } else {
          throw "invalid data type of $key : $value";
        }
      });
      if (syncTable) {
        String sqlQuery = "CREATE TABLE IF NOT EXISTS ${s.table}(${fields.join(',')})";
        if (logging) print("Execute: $sqlQuery");
        await client.execute(sqlQuery);
      }
    }
  }

  Future<Object> insert({required String table, required Map<String, dynamic> data, bool returning = false}) async {
    if (!_schemas.containsKey(table)) throw "$table does not exist";
    if (data.isEmpty) throw "Data cannot be empty";
    _InserQueryBuilder queryBuilder = _InserQueryBuilder(schema: _schemas[table]!);
    String query = queryBuilder.buildInsertQuery(data: data, returning: returning);
    if (logging) print("Executing: $query");
    if (returning) {
      return client.executeResult(query);
    } else {
      return client.execute(query);
    }
  }

  Future<Object> multiinsert({required String table, required List<Map<String, dynamic>> data, bool returning = false}) async {
    if (!_schemas.containsKey(table)) throw "$table does not exist";
    if (data.isEmpty) throw "Data cannot be empty";
    _InserQueryBuilder queryBuilder = _InserQueryBuilder(schema: _schemas[table]!);
    String query = queryBuilder.buildMultiInsertQuery(datas: data, returning: returning);
    if (logging) print(query);
    if (returning) {
      return client.executeResult(query);
    } else {
      return client.execute(query);
    }
  }

  Future<Object> update({required String table, required Map<String, dynamic> data, Map? where, bool returning = false}) async {
    if (!_schemas.containsKey(table)) throw "$table does not exist";
    if (data.isEmpty) throw "Data cannot be empty";
    _UpdateQueryBuilder queryBuilder = _UpdateQueryBuilder(schema: _schemas[table]!);
    String query = queryBuilder.buildUpdateQuery(
      data: data,
      where: where,
      returning: returning,
    );
    if (logging) print("Executing: $query");
    if (returning) {
      return client.executeResult(query);
    } else {
      return client.execute(query);
    }
  }

  Future<Object> delete({required String table, Map? where, bool returning = false}) async {
    if (!_schemas.containsKey(table)) throw "$table does not exist";
    _DeleteQueryBuilder queryBuilder = _DeleteQueryBuilder(schema: _schemas[table]!);
    String query = queryBuilder.buildDeleteQuery(where: where, returning: returning);
    if (logging) print("Executing: $query");
    if (returning) {
      return client.executeResult(query);
    } else {
      return client.execute(query);
    }
  }

  Future<List<Map<String, Object?>>> findAll({required String table, List? fields, Map? where, int? limit, int? offset, List<Map>? include, List<String>? group, Map? having, Map<String, bool>? order}) async {
    _SelectQueryBuilder queryBuilder = _SelectQueryBuilder(schemas: _schemas);
    String query = queryBuilder.buildSelectQuery(table: table, fields: fields, where: where, limit: limit, offset: offset, group: group, having: having, order: order, include: include);
    if (logging) print("Executing: $query");
    List<Map<String, dynamic>> data = await client.select(query);
    if (data.isEmpty) return [];
    return queryBuilder.parseData(dataList: data);
  }

  Future<Map<String, Object?>?> findOne({required String table, List? fields, Map? where, List<Map>? include, List<String>? group, Map? having, Map<String, bool>? order}) async {
    _SelectQueryBuilder queryBuilder = _SelectQueryBuilder(schemas: _schemas);
    String query = queryBuilder.buildSelectQuery(table: table, fields: fields, where: where, group: group, having: having, order: order, include: include, limit: 1);
    if (logging) print("Executing: $query");
    List<Map<String, dynamic>> data = await client.select(query);
    return queryBuilder.parseData(dataList: data).firstOrNull;
  }

  Future<int?> count({required String table, List? fields, Map? where, List<Map>? include, List<String>? group, Map? having}) async {
    _SelectQueryBuilder queryBuilder = _SelectQueryBuilder(schemas: _schemas);
    String query = queryBuilder.buildSelectQuery(table: table, fields: fields, where: where, group: group, having: having, include: include, isCountQuery: true);
    if (logging) print("Executing: $query");
    List<Map<String, dynamic>> data = await client.select(query);
    return data.firstOrNull?['count'];
  }

  Future<Map<String, Object?>> findAncCountAll({required String table, List? fields, Map? where, int? limit, int? offset, List<Map>? include, List<String>? group, Map? having, Map<String, bool>? order}) async {
    _SelectQueryBuilder queryBuilder = _SelectQueryBuilder(schemas: _schemas);
    _SelectQueryBuilder countQueryBuilder = _SelectQueryBuilder(schemas: _schemas);
    String findQuery = queryBuilder.buildSelectQuery(table: table, fields: fields, where: where, limit: limit, offset: offset, group: group, having: having, order: order, include: include);
    String countQuery = countQueryBuilder.buildSelectQuery(table: table, fields: fields, where: where, group: group, having: having, include: include, isCountQuery: true);
    if (logging) print("Executing: $findQuery");
    if (logging) print("Executing: $countQuery");
    var data = await Future.wait([
      client.select(findQuery),
      client.select(countQuery),
    ]);
    List<Map<String, dynamic>> rows = [];
    if (data.first.isNotEmpty) {
      rows = queryBuilder.parseData(dataList: data.first);
    }
    return {
      "count": data[1].firstOrNull?['count'],
      "rows": rows,
    };
  }
}
