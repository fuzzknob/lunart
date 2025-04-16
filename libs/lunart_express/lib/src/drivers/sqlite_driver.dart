import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart' as sl;

import '../connection/sqlite_connection.dart';
import '../types.dart';

import 'driver.dart';

class SqliteDriver implements Driver {
  SqliteDriver(this.connection);

  final SqliteConnection connection;

  @override
  Future<QueryResult?> executeSelectQuery(
    String query, [
    List<Object?> parameters = const [],
  ]) {
    return _run((db) {
      final results = db.select(query, parameters);
      return results.toList();
    });
  }

  @override
  Future<void> executeInsertQuery(
    String query, [
    List<Object?> parameters = const [],
  ]) async {
    return _execute(query, parameters);
  }

  @override
  Future<int?> executeInsertGetIdQuery(
    String query, [
    List<Object?> parameters = const [],
    String identityColumn = 'id',
  ]) {
    return _run((db) {
      db.execute(query, parameters);
      return db.lastInsertRowId;
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
  ]) {
    return _execute(query, parameters);
  }

  @override
  Future<void> executeRawQuery(String query) {
    return _execute(query);
  }

  Future<void> _execute(
    String query, [
    List<Object?> parameters = const [],
  ]) async {
    // TODO: handle writes with limited number of isolates to prevent deadlocks
    return _run((db) {
      db.execute(query, parameters);
    });
  }

  Future<T?> _run<T>(T? Function(sl.Database) cb) async {
    T? runner() {
      T? result;
      final db = sl.sqlite3.open(connection.file);
      try {
        result = cb(db);
      } finally {
        db.dispose();
      }
      return result;
    }

    if (connection.runInIsolate) {
      return Isolate.run(() async {
        return runner();
      });
    }

    return runner();
  }
}
