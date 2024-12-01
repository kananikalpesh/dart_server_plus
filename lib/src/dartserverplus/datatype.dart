// ignore_for_file: non_constant_identifier_names

class DataType {
  late String value;

  DataType(this.value);

  DataType.STRING([int? length]) : value = "VARCHAR(${length ?? 255})";

  DataType.BINARYSTRING() : value = "VARCHAR BINARY";

  DataType.TEXT() : value = "TEXT";

  DataType.TINYTEXT() : value = "TINYTEXT";

  DataType.CITEXT() : value = "CITEXT";

  DataType.TSVECTOR() : value = "TSVECTOR";

  DataType.BOOLEAN() : value = "BOOLEAN";

  DataType.INTEGER() : value = "INTEGER";

  DataType.SMALLINT() : value = "SMALLINT";

  DataType.BIGINT([int? length]) : value = length == null ? "BIGINT" : "BIGINT($length)";

  DataType.FLOAT([int? limit, int? decimal]) {
    if (limit == null && decimal == null) {
      value = "FLOAT";
    } else if (limit != null && decimal != null) {
      value = "FLOAT($limit,$decimal)";
    } else if (limit != null) {
      value = "FLOAT($limit)";
    } else {
      value = "FLOAT";
    }
  }

  DataType.DOUBLE([int? limit, int? decimal]) {
    if (limit == null && decimal == null) {
      value = "DOUBLE";
    } else if (limit != null && decimal != null) {
      value = "DOUBLE($limit,$decimal)";
    } else if (limit != null) {
      value = "DOUBLE($limit)";
    } else {
      value = "DOUBLE";
    }
  }

  DataType.DECIMAL([int? limit, int? decimal]) {
    if (limit == null && decimal == null) {
      value = "DECIMAL";
    } else if (limit != null && decimal != null) {
      value = "DECIMAL($limit,$decimal)";
    } else if (limit != null) {
      value = "DECIMAL($limit)";
    } else {
      value = "DECIMAL";
    }
  }

  DataType.REAL([int? limit, int? decimal]) {
    if (limit == null && decimal == null) {
      value = "REAL";
    } else if (limit != null && decimal != null) {
      value = "REAL($limit,$decimal)";
    } else if (limit != null) {
      value = "REAL($limit)";
    } else {
      value = "REAL";
    }
  }

  DataType.NUMERIC([int? limit, int? decimal]) {
    if (limit == null && decimal == null) {
      value = "NUMERIC";
    } else if (limit != null && decimal != null) {
      value = "NUMERIC($limit,$decimal)";
    } else if (limit != null) {
      value = "NUMERIC($limit)";
    } else {
      value = "NUMERIC";
    }
  }

  DataType.INTEGERARRAY() : value = "INTEGER[]";

  DataType.VARCHARARRAY([int length = 100]) : value = "VARCHAR($length)[]";

  DataType.DATE() : value = "DATE";

  DataType.TIME() : value = "TIME";

  DataType.TIMESTAMP([bool withTimeZone = false]) : value = withTimeZone ? "TIMESTAMP WITH TIME ZONE" : "TIMESTAMP";

  DataType.UUID() : value = "UUID";

  DataType.BYTEA() : value = "BYTEA";

  DataType.SERIAL() : value = "SERIAL";

  DataType.BIGSERIAL() : value = "BIGSERIAL";

  DataType.VALUE(String v) : value = v;
}
