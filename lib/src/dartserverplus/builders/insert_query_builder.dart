part of '../dartserverplus.dart';

class _InserQueryBuilder extends _QueryBuilder {
  final Schema schema;
  _InserQueryBuilder({required this.schema});

  String buildInsertQuery({required Map<String, dynamic> data, bool returning = false}) {
    String? primaryKey = getPrimaryKeyOfTable();
    List<String> fields = schema.fields.keys.where((k) => !(schema.fields[k] is Map && !data.containsKey(k) && (schema.fields[k] as Map).containsKey("default"))).toList();
    if (!data.containsKey(primaryKey)) {
      fields.remove(primaryKey);
    }
    String columns = fields.join(', ');
    String values = fields.map((e) => data[e] == null ? 'NULL' : "'${data[e]}'").join(', ');
    String query = "INSERT INTO ${schema.table} ($columns) VALUES ($values)";
    if (returning) {
      query += " RETURNING *";
    }
    return query;
  }

  String buildMultiInsertQuery({required List<Map<String, dynamic>> datas, bool returning = false}) {
    String? primaryKey = getPrimaryKeyOfTable();
    List<String> fields = schema.fields.keys.toList();
    if (schema.fields[primaryKey]['autoIncrement'] == true || (schema.fields[primaryKey] is Map && schema.fields[primaryKey]['default'] != null)) {
      fields.remove(primaryKey);
    }
    String columns = fields.join(', ');
    String values = datas
        .where((element) => element.isNotEmpty)
        .map((data) => fields
            .map((e) => data[e] == null
                ? schema.fields[e] is! Map
                    ? 'NULL'
                    : schema.fields[e]['default'] ?? 'NULL'
                : "'${data[e]}'")
            .join(', '))
        .map((e) => "($e)")
        .join(', ');
    String query = "INSERT INTO ${schema.table} ($columns) VALUES $values";
    if (returning) {
      query += " RETURNING *";
    }
    return query;
  }

  String? getPrimaryKeyOfTable() {
    for (MapEntry entry in schema.fields.entries) {
      if (entry.value is Map && entry.value['primaryKey'] == true) {
        if (entry.value['autoIncrement'] == true || ['SERIAL', 'BIGSERIAL', 'UUID'].contains((entry.value['type'] as DataType).value)) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
