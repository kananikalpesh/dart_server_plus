abstract class DatabaseClient {
  Future<void> connect();
  Future<List<Map<String, dynamic>>> select(String query);
  Future<int> execute(String query);
  Future<Object> executeResult(String query);
}
