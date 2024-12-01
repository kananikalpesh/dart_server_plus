import '../database_client.dart';
import 'package:mysql_client/mysql_client.dart';

class MysqlClient extends DatabaseClient {
  bool _isPoolConnection = false;
  late final MySQLConnection _mySQLConnection;
  late final MySQLConnectionPool _mySQLConnectionPool;

  final dynamic host;
  final int port;
  final String userName;
  final String password;
  final bool secure;
  final String? databaseName;
  final String collation;
  final int timeoutMs;
  late final int maxConnections;

  MysqlClient({
    required this.host,
    required this.port,
    required this.userName,
    required this.password,
    this.timeoutMs = 10000,
    this.secure = true,
    this.databaseName,
    this.collation = 'utf8mb4_general_ci',
  });

  MysqlClient.createConnection({
    required this.host,
    required this.port,
    required this.userName,
    required this.password,
    this.timeoutMs = 10000,
    this.secure = true,
    this.databaseName,
    this.collation = 'utf8mb4_general_ci',
  });

  MysqlClient.createConnectionPool({
    required this.host,
    required this.port,
    required this.userName,
    required this.password,
    required this.maxConnections,
    this.secure = true,
    this.databaseName,
    this.collation = 'utf8mb4_general_ci',
    this.timeoutMs = 10000,
  }) : _isPoolConnection = true;

  @override
  Future<void> connect() async {
    if (_isPoolConnection) {
      _mySQLConnectionPool = MySQLConnectionPool(
        host: host,
        port: port,
        userName: userName,
        password: password,
        maxConnections: maxConnections,
        databaseName: databaseName,
        collation: collation,
        timeoutMs: timeoutMs,
        secure: secure,
      );
    } else {
      _mySQLConnection = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: userName,
        password: password,
        databaseName: databaseName,
        collation: collation,
        secure: secure,
      );
      await _mySQLConnection.connect(timeoutMs: timeoutMs);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> select(String query) async {
    IResultSet res;
    if (_isPoolConnection) {
      res = await _mySQLConnectionPool.execute(query);
    } else {
      res = await _mySQLConnection.execute(query);
    }
    return res.rows.map((e) => e.assoc()).toList();
  }

  @override
  Future<int> execute(String query) async {
    IResultSet res;
    if (_isPoolConnection) {
      res = await _mySQLConnectionPool.execute(query);
    } else {
      res = await _mySQLConnection.execute(query);
    }
    return res.affectedRows.toInt();
  }

  @override
  Future<Object> executeResult(String query) async {
    IResultSet res;
    if (_isPoolConnection) {
      res = await _mySQLConnectionPool.execute(query);
    } else {
      res = await _mySQLConnection.execute(query);
    }
    return res.rows.map((e) => e.assoc()).toList();
  }
}
