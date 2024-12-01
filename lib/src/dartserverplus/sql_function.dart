class SQLFunction {
  final String function;
  final String column;
  final String alias;
  SQLFunction({required this.function, required this.column, required this.alias});
}

class SQLLiteral {
  final String value;
  SQLLiteral(this.value);
}
