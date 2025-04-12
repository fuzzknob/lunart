import 'package:postgres/postgres.dart' as pg;

import '../connection/postgres_connection.dart';
import '../types.dart';
import 'driver.dart';

class PostgresDriver implements Driver {
  PostgresDriver(this.connection);

  final PostgresConnection connection;

  @override
  Future<QueryResult?> executeSelectQuery(
    String query, [
    List<Object?> parameters = const [],
  ]) {
    return _run((db) async {
      final result = await db.execute(query, parameters: parameters);
      return _toQueryResult(result);
    });
  }

  @override
  Future<void> executeInsertQuery(
    String query, [
    List<Object?> parameters = const [],
  ]) {
    return _execute(query, parameters);
  }

  @override
  Future<Object?> executeInsertGetIdQuery(
    String query, [
    List<Object?> parameters = const [],
    String identityColumn = 'id',
  ]) {
    return _run((db) async {
      final result = await db.execute(query, parameters: parameters);
      final data = _toQueryResult(result);
      return data?.first[identityColumn];
    });
  }

  @override
  Future<void> executeUpdateQuery(
    String query, [
    List<Object?> parameters = const [],
  ]) async {
    return _execute(query, parameters);
  }

  @override
  Future<void> executeDeleteQuery(
    String query, [
    List<Object?> parameters = const [],
  ]) async {
    return _execute(query, parameters);
  }

  @override
  Future<void> executeRawQuery(String query) async {
    return _execute(query);
  }

  Future<void> _execute(
    String query, [
    List<Object?> parameters = const [],
  ]) async {
    await _run((db) {
      return db.execute(query, parameters: parameters);
    });
  }

  Future<T?> _run<T>(Future<T?> Function(pg.Connection) cb) async {
    final db = await pg.Connection.open(
      pg.Endpoint(
        database: connection.database,
        host: connection.host,
        port: connection.port,
        username: connection.username,
        password: connection.password,
      ),
      settings: pg.ConnectionSettings(
        sslMode: switch (connection.sslMode) {
          PostgresSslMode.disable => pg.SslMode.disable,
          PostgresSslMode.require => pg.SslMode.require,
          PostgresSslMode.verifyFull => pg.SslMode.verifyFull,
        },
      ),
    );
    try {
      final result = await cb(db);
      return result;
    } finally {
      await db.close();
    }
  }

  QueryResult? _toQueryResult(pg.Result result) {
    return result.map((row) => row.toColumnMap()).toList();
  }
}
