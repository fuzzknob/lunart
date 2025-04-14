import '../drivers/sqlite_driver.dart';
import '../query/grammar/sqlite_grammar.dart';
import 'connection.dart';

// enum SqliteConnectionMode { inMemory, file }

class SqliteConnection implements Connection {
  SqliteConnection({required this.file, this.pool, this.runInIsolate = true});

  final String file;
  final int? pool;
  final bool runInIsolate;

  factory SqliteConnection.file(
    String file, {
    int? pool,
    bool runInIsolate = true,
  }) => SqliteConnection(file: file, pool: pool, runInIsolate: runInIsolate);

  // TODO: find a better way to support in memory sqlite
  // factory SqliteConnection.memory({int? pool, bool runInIsolate = false}) =>
  //     SqliteConnection(
  //       mode: SqliteConnectionMode.inMemory,
  //       pool: pool,
  //       runInIsolate: runInIsolate,
  //     );

  @override
  SqliteDriver get driver => SqliteDriver(this);

  @override
  SqliteGrammar get grammar => SqliteGrammar();
}
