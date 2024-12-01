part of '../dartserverplus.dart';

class _UpdateQueryBuilder extends _QueryBuilder {
  _UpdateQueryBuilder({required this.schema});
  final Schema schema;

  String buildUpdateQuery({required Map<String, dynamic> data, Map? where, bool returning = false}) {
    String fields = data.entries.map((e) => "${e.key}='${e.value}'").join(', ');
    String query = "UPDATE ${schema.table} SET $fields";
    if ((where ?? {}).isNotEmpty) {
      query += " WHERE ${getWhereCondition(where, '')}";
    }
    if (returning) {
      query += " RETURNING *";
    }
    return query;
  }
}
