import 'connection.dart';

enum SqliteConnectionMode { inMemory, file }

class SqliteConnection implements Connection {
  SqliteConnection({
    required this.mode,
    this.file,
    this.pool,
    this.runInIsolate = true,
  });

  final SqliteConnectionMode mode;
  final String? file;
  final int? pool;
  final bool runInIsolate;

  factory SqliteConnection.file(
    String file, {
    int? pool,
    bool runInIsolate = true,
  }) => SqliteConnection(
    mode: SqliteConnectionMode.file,
    file: file,
    pool: pool,
    runInIsolate: runInIsolate,
  );

  factory SqliteConnection.memory({int? pool, bool runInIsolate = false}) =>
      SqliteConnection(
        mode: SqliteConnectionMode.file,
        pool: pool,
        runInIsolate: runInIsolate,
      );
}
