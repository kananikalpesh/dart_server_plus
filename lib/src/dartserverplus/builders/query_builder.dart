part of '../dartserverplus.dart';

abstract class _QueryBuilder {
  String getWhereCondition(Map? where, String table) {
    List<String> wheres = [];
    where?.forEach((key, value) {
      if (key is Op) {
        wheres.add(getOperatorvalue(key, value, table));
      } else {
        value ??= 'NULL';
        if (value == 'NULL') {
          wheres.add("${parseKey(key, "$table$key")} IS $value");
        } else {
          if (key is String && value is Map) {
            String val = getConditionFromMap(value, table);
            wheres.add("$table$key $val");
          } else if (key is SQLLiteral && value is Map) {
            String val = getConditionFromMap(value, table);
            wheres.add("${key.value} $val");
          } else {
            wheres.add("${parseKey(key, "$table$key")} = ${parsevalue(value, '$value')}");
          }
        }
      }
    });
    return wheres.join(' AND ');
  }

  String getConditionFromMap(Map value, String table) {
    List l = [];
    value.forEach((key, val) {
      if (key is Op) {
        l.add(getOperatorvalue(key, val, table));
      } else if (val is Map) {
        l.add(getConditionFromMap(val, table));
      } else {
        var v = val ?? 'NULL';
        if (v == 'NULL') {
          l.add("${parseKey(key, "$table$key")} IS $v");
        } else {
          l.add("${parseKey(key, "$table$key")} = ${parsevalue(val, "'$val'")}");
        }
      }
    });
    return l.join(' AND ');
  }

  String getOperatorvalue(Op key, Object value, String table) {
    switch (key) {
      case Op.eq:
        return " = ${parsevalue(value, "'$value'")}";
      case Op.gt:
        return " > ${parsevalue(value, "'$value'")}";
      case Op.lt:
        return " < ${parsevalue(value, "'$value'")}";
      case Op.gte:
        return " >= ${parsevalue(value, "'$value'")}";
      case Op.lte:
        return " <= ${parsevalue(value, "'$value'")}";
      case Op.like:
        return " LIKE ${parsevalue(value, "'%$value%'")}";
      case Op.notLike:
        return " NOT LIKE ${parsevalue(value, "'%$value%'")}";
      case Op.ilike:
        return " ILIKE ${parsevalue(value, "'%$value%'")}";
      case Op.notiLike:
        return " NOT ILIKE ${parsevalue(value, "'%$value%'")}";
      case Op.iN:
        if (value is! List) throw "Invalid value for $key : $value";
        return " IN (${value.join(',')})";
      case Op.notIn:
        if (value is! List) throw "Invalid value for $key : $value";
        return " NOT IN (${value.join(',')})";
      case Op.neq:
        return " != ${parsevalue(value, "'$value'")}";
      case Op.between:
        if (value is! List || value.length != 2) throw "Invalid value for $key : $value";
        return " BETWEEN ${parsevalue(value[0], "'${value[0]}'")} AND ${parsevalue(value[1], "'${value[1]}'")}";
      case Op.notBetween:
        if (value is! List || value.length != 2) throw "Invalid value for $key : $value";
        return " NOT BETWEEN ${parsevalue(value[0], "'${value[0]}'")} AND ${parsevalue(value[1], "'${value[1]}'")}";
      case Op.and || Op.or:
        return getAndOrValue(value, key, table);
      case Op.not:
        if (value is! Map) throw "Invalid value for $key : $value";
        return getNotvalue(value, key, table);
      default:
        return "";
    }
  }

  String getAndOrValue(Object val, Op operator, String table) {
    if (val is! Map && val is! List) "Invalid value for $operator : $val";
    if ((val is Map && val.isEmpty) || (val is List && val.isEmpty)) throw "Invalid value for $operator : $val";
    List l = [];
    if (val is List) {
      for (var v in val) {
        l.add(getAndOrValue(v, Op.and, table));
      }
    } else if (val is Map) {
      val.forEach((key, value) {
        if (value is Op) {
          if (value == Op.and || value == Op.and || value == Op.not) {
            l.add(getAndOrValue(value, key, table));
          } else {
            String s = getOperatorvalue(key, value, table);
            l.add("$key$s");
          }
        } else if (value is Map) {
          String s = getConditionFromMap(value, table);
          if (value.keys.isNotEmpty && value.keys.first is Op) {
            l.add("$key$s");
          } else {
            l.add("${parseKey(key, "$table$key")} = $s");
          }
        } else {
          var v = value ?? 'NULL';
          if (v == 'NULL') {
            l.add("${parseKey(key, "$table$key")} IS $value");
          } else {
            l.add("${parseKey(key, "$table$key")} = ${parsevalue(value, "'$value'")}");
          }
        }
      });
    }
    String s = l.join(" ${operator == Op.and ? 'AND' : 'OR'} ");
    return "($s)";
  }

  String getNotvalue(Object val, Op operator, String table) {
    if (val is Op) {
      String s = getOperatorvalue(val, operator, table);
      return "NOT ($s)";
    }
    if (val is! Map || val.isEmpty) throw "Invalid value for $operator : $val";
    List l = [];
    val.forEach((key, value) {
      if (value is Op) {
        l.add(getOperatorvalue(key, value, table));
      } else {
        var v = value ?? 'NULL';
        if (v == 'NULL') {
          l.add("${parseKey(key, "$table$key")} IS $v");
        } else {
          l.add("${parseKey(key, "$table$key")} = ${parsevalue(value, "'$value'")}");
        }
      }
    });
    return "NOT (${l.join(' AND ')})";
  }

  Object parseKey(Object obj, String key) {
    if (obj is SQLLiteral) return obj.value;
    return key;
  }

  Object parsevalue(Object obj, String value) {
    if (obj is SQLLiteral) return obj.value;
    if (!value.startsWith("'")) value = "'$value'";
    return value;
  }
}
