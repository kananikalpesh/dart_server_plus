part of '../dartserverplus.dart';


class Transactions {
  Transactions({required this.client, this.logging = false});
  final DatabaseClient client;
  final bool logging;

  Future<void> start() async {
    if (logging) print("Executing: START TRANSACTION");
    await client.execute("START TRANSACTION");
  }

  Future<void> commit() async {
    if (logging) print("Executing: COMMIT");
    await client.execute("COMMIT");
  }

  Future<void> rollback() async {
    if (logging) print("Executing: ROLLBACK");
    await client.execute("ROLLBACK");
  }

  Future<void> rollbackTO({required String savepoint}) async {
    if (logging) print("Executing: ROLLBACK TO SAVEPOINT $savepoint");
    await client.execute("ROLLBACK TO SAVEPOINT $savepoint");
  }

  Future<void> savePoint({required String savepoint}) async {
    if (logging) print("Executing: SAVEPOINT $savepoint");
    await client.execute("SAVEPOINT $savepoint");
  }

  Future<void> releaseSavePoint({required String savepoint}) async {
    if (logging) print("Executing: RELEASE SAVEPOINT  $savepoint");
    await client.execute("RELEASE SAVEPOINT  $savepoint");
  }
}
