part of '../dartserverplus.dart';

class _DeleteQueryBuilder extends _QueryBuilder {
  _DeleteQueryBuilder({required this.schema});
  final Schema schema;

  String buildDeleteQuery({Map? where, bool returning = false}) {
    String query = "DELETE FROM ${schema.table}";
    if ((where ?? {}).isNotEmpty) {
      query += " WHERE ${getWhereCondition(where, '')}";
    }
    if (returning) {
      query += " RETURNING *";
    }
    return query;
  }
}
