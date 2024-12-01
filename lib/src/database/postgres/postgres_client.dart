import '../database_client.dart';
import 'package:postgres/postgres.dart';

class PostgresClient extends DatabaseClient {
  final String host;
  final String database;
  final String? userName;
  final String? password;
  final bool isUnixSocket;
  final int port;

  PostgresClient({
    required this.host,
    required this.database,
    this.userName,
    this.password,
    this.port = 5432,
    this.isUnixSocket = false,
  });

  late final Connection connection;

  @override
  Future<void> connect() async {
    connection = await Connection.open(
      Endpoint(host: host, database: database, username: userName, password: password, port: port, isUnixSocket: isUnixSocket),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> select(String query) async {
    Result result = await connection.execute(query);
    return result.map((element) => element.toColumnMap()).toList();
  }

  @override
  Future<int> execute(String query) async {
    Result result = await connection.execute(query);
    return result.affectedRows;
  }

  @override
  Future<Object> executeResult(String query) async {
    Result result = await connection.execute(query);
    return result.map((element) => element.toColumnMap()).toList();
  }
}
