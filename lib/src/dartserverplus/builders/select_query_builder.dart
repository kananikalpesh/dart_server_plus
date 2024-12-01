part of '../dartserverplus.dart';

class _SelectQueryBuilder extends _QueryBuilder {
  final Map<String, Schema> schemas;
  _SelectQueryBuilder({required this.schemas});

  Map<String, dynamic> responseStructure = {};
  String joinString = "";
  String columns = "";
  String groupBy = "";
  String havingCondition = "";
  String orderBy = "";

  Map<dynamic, dynamic> responseMapping = {};

  String buildSelectQuery({
    required String table,
    List? fields,
    Map? where,
    int? limit,
    int? offset,
    List<Map>? include,
    List<String>? group,
    Map? having,
    Map<String, bool>? order,
    bool isCountQuery = false,
  }) {
    if (!schemas.containsKey(table)) throw "$table table does not exist";
    List fieldsList = fields ?? (schemas[table]?.fields.keys.toList() ?? []);
    String? mainTablePrimarykey = getPrimaryKeyOfTable(table);
    if (mainTablePrimarykey == null) throw "$table does not contains any primary key";
    columns = getTableFields(fieldsList, table, mainTablePrimarykey, group == null);

    String? groupByFirst;
    if ((group ?? []).isNotEmpty) {
      groupByFirst = group?.firstOrNull;
      groupBy = "GROUP BY ${group!.map((e) => "\"$table\".$e").join(', ')}";
      if ((having ?? {}).isNotEmpty) {
        havingCondition = getWhereCondition(having, "\"$table\".");
      }
    }
    if ((order ?? {}).isNotEmpty) {
      orderBy = "Order BY ";
      orderBy += order!.entries.map((e) => "\"$table\".${e.key} ${e.value ? 'ASC' : 'DESC'}").join(', ');
    }

    responseStructure = {
      'fields': {}..addEntries(fieldsList.map((e) => e is SQLFunction ? MapEntry(e.alias, "$table.${e.alias}") : MapEntry(e, "$table.$e"))),
      'table': table,
      'primary_key': mainTablePrimarykey,
      'mapping_key': "$table.$mainTablePrimarykey",
      if (groupByFirst != null) ...{
        'group_key': groupByFirst,
        'group_mapping_key': "$table.$groupByFirst",
      }
    };

    if ((include ?? []).isNotEmpty) {
      for (Map obj in include ?? []) {
        if (obj['table'] == null) throw "Syntax is not match for include";
        if (!schemas.containsKey(obj['table'])) throw "${obj['table']} table does not exist";
        String? primaryKey = getPrimaryKeyOfTable(obj['table']);
        if (primaryKey == null) throw "${obj['table']} does not contains any primary key";
        List fieldsList = obj['fields'] as List? ?? (schemas[obj['table']]?.fields.keys.toList() ?? []);
        columns += ",${getTableFields(fieldsList, obj['table'], primaryKey, obj['group'] == null)}";

        String? groupByFirstStr;
        if (obj['group'] != null && obj['group'] is List) {
          String groupStr = (obj['group'] as List).map((e) => "\"${obj['table']}\".$e").join(', ');
          groupByFirstStr = (obj['group'] as List).firstOrNull;
          if (groupStr.isNotEmpty) {
            if (groupBy.isEmpty) {
              groupBy = "GROUP BY $groupStr";
            } else {
              groupBy += ", $groupStr";
            }
          }
          if (obj['having'] != null && obj['having'] is Map && obj['table'].isNotEmpty) {
            String havingStr = getWhereCondition(obj['having'], '"${obj['table']}".');
            if (havingStr.isNotEmpty) {
              if (havingCondition.isEmpty) {
                havingCondition = havingStr;
              } else {
                havingCondition += " AND $havingStr";
              }
            }
          }
        }

        if (obj['order'] != null && obj['order'] is Map && (obj['order'] ?? {}).isNotEmpty) {
          orderBy += orderBy.isEmpty ? "Order BY " : ", ";
          orderBy += obj['order']!.entries.map((e) => "\"${obj['table']}\".${e.key} ${e.value ? 'ASC' : 'DESC'}").join(', ');
        }

        Map<String, dynamic> responseStructureData = {
          'fields': {}..addEntries(fieldsList.map((e) => e is SQLFunction ? MapEntry(e.alias, "${obj['table']}.${e.alias}") : MapEntry(e, "${obj['table']}.$e"))),
          'table': obj['table'],
          'primary_key': primaryKey,
          'mapping_key': "${obj['table']}.$primaryKey",
          if (groupByFirstStr != null) ...{
            'group_key': groupByFirstStr,
            'group_mapping_key': "${obj['table']}.$groupByFirstStr",
          }
        };
        responseStructure['include'] ??= [];
        responseStructure['include']?.add(responseStructureData);

        String condition = "";
        schemas[table]?.fields.forEach((key, value) {
          if (value is Map && value['reference'] != null) {
            if (value['reference']?['table'] == obj['table']) {
              condition = "$table.${value['reference']?['column']}=${obj['table']}.$key";
            }
          }
        });
        if (condition.isEmpty) {
          schemas[obj['table']]?.fields.forEach((key, value) {
            if (value is Map && value['reference'] != null) {
              if (value['reference']?['table'] == table) {
                condition = "${value['reference']?['table']}.${value['reference']?['column']}=${obj['table']}.$key";
              }
            }
          });
        }

        String whereCondition = "";
        String join = "LEFT JOIN";
        if (obj['where'] != null && obj['where'] is Map && obj['where'].isNotEmpty) {
          whereCondition = " AND ${getWhereCondition(obj['where'], '"${obj['table']}".')}";
          join = "INNER JOIN";
        }

        if (condition.isEmpty) throw "Something is wrong with included table";
        joinString += "$join ${obj['table']} AS \"${obj['table']}\" ON($condition$whereCondition) ";

        if (obj.containsKey('include')) {
          if (obj['include'] is! List) throw "Invalid include: ${obj['include']}";
          for (var o in obj['include']) {
            if (o is! Map) throw "Invalid include: $o";
            addIncludeTable(o, obj['table'], responseStructureData);
          }
        }
      }
    }

    String limitOffset = "";
    if (limit != null) limitOffset = "LIMIT $limit";
    if (offset != null) limitOffset += " OFFSET $offset";

    String whereCondition = "";
    if (where != null && where.isNotEmpty) {
      whereCondition = getWhereCondition(where, "\"$table\".");
    }

    String subQuery = "$table AS \"$table\"";
    if (limitOffset.isNotEmpty && (include ?? []).isEmpty) {
      if (whereCondition.isNotEmpty) {
        subQuery += " WHERE $whereCondition";
      }
      subQuery += " $limitOffset";
    } else if (limitOffset.isNotEmpty && whereCondition.isNotEmpty) {
      subQuery = "(SELECT * FROM $table WHERE $whereCondition $limitOffset) AS \"$table\"";
    } else if (limitOffset.isNotEmpty) {
      subQuery = "(SELECT * FROM $table $limitOffset) AS \"$table\"";
    } else if (whereCondition.isNotEmpty) {
      joinString += " WHERE $whereCondition";
    }

    if (havingCondition.isNotEmpty) {
      groupBy += " HAVING $havingCondition";
    }

    if (isCountQuery) {
      String selectColumn = "*";
      if ((include ?? []).isNotEmpty) {
        selectColumn = "\"$table\".$mainTablePrimarykey";
      }
      return "SELECT Count($selectColumn) as count FROM $table AS \"$table\" $joinString $groupBy $orderBy";
    }

    return "SELECT $columns FROM $subQuery $joinString $groupBy $orderBy";
  }

  void addIncludeTable(Map includeObj, String tableNames, Map<String, dynamic> responseStructureData, {bool isRecursive = false}) {
    String tableNameTrimmed = tableNames.split("->").last;
    if (includeObj['table'] == null) throw "Syntax is not match for include";
    if (!schemas.containsKey(includeObj['table'])) throw "${includeObj['table']} does not exist";
    String? primaryKey = getPrimaryKeyOfTable(includeObj['table']);
    if (primaryKey == null) throw "${includeObj['table']} does not contains any primary key";
    List fieldsList = includeObj['fields'] as List? ?? (schemas[includeObj['table']]?.fields.keys.toList() ?? []);
    columns += ",${getTableFields(fieldsList, "$tableNames->${includeObj['table']}", primaryKey, includeObj['group'] == null)}";

    String? groupByFirstStr;
    if (includeObj['group'] != null && includeObj['group'] is List) {
      String groupStr = (includeObj['group'] as List).map((e) => "\"$tableNames->${includeObj['table']}\".$e").join(', ');
      groupByFirstStr = includeObj['group']?.firstOrNull;
      if (groupStr.isNotEmpty) {
        if (groupBy.isEmpty) {
          groupBy = "GROUP BY $groupStr";
        } else {
          groupBy += ", $groupStr";
        }
      }

      if (includeObj['having'] != null && includeObj['having'] is Map && includeObj['table'].isNotEmpty) {
        String havingStr = getWhereCondition(includeObj['having'], '"$tableNames->${includeObj['table']}".');
        if (havingStr.isNotEmpty) {
          if (havingCondition.isEmpty) {
            havingCondition = havingStr;
          } else {
            havingCondition += " AND $havingStr";
          }
        }
      }
    }

    if (includeObj['order'] != null && includeObj['order'] is Map && (includeObj['order'] ?? {}).isNotEmpty) {
      orderBy += orderBy.isEmpty ? "Order BY " : ", ";
      orderBy += includeObj['order']!.entries.map((e) => "\"$tableNames->${includeObj['table']}\".${e.key} ${e.value ? 'ASC' : 'DESC'}").join(', ');
    }

    Map<String, dynamic> responseStructureDatas = {
      'fields': {}..addEntries(fieldsList.map((e) => e is SQLFunction ? MapEntry(e.alias, "$tableNames->${includeObj['table']}.${e.alias}") : MapEntry(e, "$tableNames->${includeObj['table']}.$e"))),
      'table': includeObj['table'],
      'primary_key': primaryKey,
      'mapping_key': "$tableNames->${includeObj['table']}.$primaryKey",
      if (groupByFirstStr != null) ...{
        'group_key': groupByFirstStr,
        'group_mapping_key': "$tableNames->${includeObj['table']}.$groupByFirstStr",
      }
    };
    responseStructureData['include'] ??= [];
    responseStructureData['include']?.add(responseStructureDatas);

    String condition = "";
    schemas[tableNameTrimmed]?.fields.forEach((key, value) {
      if (value is Map && value['reference'] != null) {
        if (value['reference']?['table'] == includeObj['table']) {
          if (isRecursive) {
            condition = "\"$tableNames\".${value['reference']?['column']}=\"$tableNames->${includeObj['table']}\".$key";
          } else {
            condition = "$tableNames.${value['reference']?['column']}=\"$tableNames->${includeObj['table']}\".$key";
          }
        }
      }
    });
    if (condition.isEmpty) {
      schemas[includeObj['table']]?.fields.forEach((key, value) {
        if (value is Map && value['reference'] != null) {
          if (value['reference']?['table'] == tableNameTrimmed) {
            if (isRecursive) {
              condition = "\"${value['reference']?['table']}\".${value['reference']?['column']}=$tableNames.$key";
            } else {
              condition = "${value['reference']?['table']}.${value['reference']?['column']}=$tableNames.$key";
            }
          }
        }
      });
    }

    String whereCondition = "";
    String join = "LEFT JOIN";
    if (includeObj['where'] != null && includeObj['where'] is Map && includeObj['where'].isNotEmpty) {
      whereCondition = " AND ${getWhereCondition(includeObj['where'], '"$tableNames->${includeObj['table']}".')}";
      join = "INNER JOIN";
    }

    if (condition.isEmpty) throw "Something is wrong with included table";
    joinString += "$join ${includeObj['table']} AS \"$tableNames->${includeObj['table']}\" ON($condition$whereCondition) ";

    if (includeObj.containsKey('include')) {
      if (includeObj['include'] is! List) throw "Invalid include: ${includeObj['include']}";
      for (var o in includeObj['include']) {
        if (o is! Map) throw "Invalid include: $o";
        addIncludeTable(o, "$tableNames->${includeObj['table']}", responseStructureDatas, isRecursive: true);
      }
    }
  }

  String? getPrimaryKeyOfTable(String table) {
    for (MapEntry entry in schemas[table]?.fields.entries ?? const Iterable.empty()) {
      if (entry.value is Map && entry.value['primaryKey'] == true) {
        return entry.key;
      }
    }
    return null;
  }

  String getTableFields(List fields, String table, String primaryKey, [bool canAddPrimaryKey = true]) {
    bool primaryKeyIncluded = false;
    List<String> columns = [];
    for (var s in fields) {
      if (s is String) {
        columns.add("\"$table\".$s AS \"$table.$s\"");
        if (s == primaryKey) primaryKeyIncluded = true;
      } else if (s is SQLFunction) {
        columns.add("${s.function}(\"$table\".${s.column}) AS \"$table.${s.alias}\"");
      }
      // else if (s is Map<String, String> && s.isNotEmpty) {
      //   s.forEach((key, value) {
      //     columns.add('$key AS $value');
      //   });
      // }
    }
    if (!primaryKeyIncluded && canAddPrimaryKey) columns.insert(0, "\"$table\".$primaryKey AS \"$table.$primaryKey\"");
    return columns.join(",");
  }

  List<Map<String, Object?>> parseData({required List<Map<String, dynamic>> dataList}) {
    List<Map<String, dynamic>> modifiedData = [];
    int len = dataList.length;
    for (int i = 0; i < len; i++) {
      Map<String, dynamic> data = dataList[i];

      bool primaryKeyContains = !responseMapping.containsKey(data[responseStructure['mapping_key']]);
      bool groupMappingContains = (responseStructure.containsKey('group_mapping_key') && !data.containsKey(responseStructure['group_mapping_key']));

      if (groupMappingContains || primaryKeyContains) {
        responseMapping[data[responseStructure['mapping_key']]] = Map<dynamic, dynamic>.from({'index': modifiedData.length});
        modifiedData.add(Map<String, dynamic>.from({}));
        Map<String, dynamic> modifiedMapData = modifiedData[responseMapping[data[responseStructure['mapping_key']]]['index']];
        (responseStructure['fields'] as Map).forEach((key, value) {
          modifiedMapData[key] = data[value];
        });
      }
      for (Map<String, dynamic> includeStructure in responseStructure['include'] ?? []) {
        Map<String, dynamic> modifiedMapData = modifiedData[responseMapping[data[responseStructure['mapping_key']]]['index']];
        parseIncludeData(data, modifiedMapData, includeStructure, responseMapping[data[responseStructure['mapping_key']]]);
      }
    }
    return List.from(modifiedData);
  }

  void parseIncludeData(Map data, Map modifiedData, Map responseStructureData, Map responseMappingData) {
    modifiedData[responseStructureData['table']] ??= [];
    responseMappingData[responseStructureData['table']] ??= {};
    bool primayKeyContains = !(responseMappingData[responseStructureData['table']] as Map).containsKey(data[responseStructureData['mapping_key']]);

    if (primayKeyContains) {
      responseMappingData[responseStructureData['table']][data[responseStructureData['mapping_key']]] = Map<dynamic, dynamic>.from({'index': modifiedData[responseStructureData['table']]?.length ?? 0});
      modifiedData[responseStructureData['table']]?.add(Map<String, dynamic>.from({}));
      Map<String, dynamic> modifiedMapData = modifiedData[responseStructureData['table']][responseMappingData[responseStructureData['table']][data[responseStructureData['mapping_key']]]['index']];
      (responseStructureData['fields'] as Map).forEach((key, value) {
        modifiedMapData[key] = data[value];
      });
    }
    for (Map<String, dynamic> includeStructure in responseStructureData['include'] ?? []) {
      Map<String, dynamic> modifiedMapData = modifiedData[responseStructureData['table']][responseMappingData[responseStructureData['table']][data[responseStructureData['mapping_key']]]['index']];
      parseIncludeData(data, modifiedMapData, includeStructure, responseMappingData[responseStructureData['table']][data[responseStructureData['mapping_key']]]);
    }
  }
}
