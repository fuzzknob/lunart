import 'query/query_builder.dart';
import 'query/grammar/grammar.dart';
import 'query/grammar/sqlite_grammar.dart';
import 'query/grammar/postgres_grammar.dart';
import 'drivers/driver.dart';
import 'drivers/sqlite_driver.dart';
import 'drivers/postgres_driver.dart';
import 'exceptions/luex_exception.dart';
import 'connection/connection.dart';
import 'connection/sqlite_connection.dart';
import 'connection/postgres_connection.dart';

import 'runner.dart';

class Database {
  Database(this.connections) {
    if (connections['default'] == null) {
      throw Exception('Please specify a default connection');
    }
  }

  final Map<String, Connection> connections;

  factory Database.init(Connection connection) =>
      Database({'default': connection});

  QueryBuilder table(
    String table, {
    String connectionName = 'default',
    String identityColumn = 'id',
  }) {
    final connection = getConnection(connectionName);
    final driver = getDriver(connection);
    final grammar = getGrammar(connection);
    final runner = Runner(driver);

    return QueryBuilder(
      table: table,
      identityColumn: identityColumn,
      grammar: grammar,
      runner: runner,
    );
  }

  Connection getConnection(String name) {
    final connection = connections[name];
    if (connection == null) {
      throw LuexException('Connection $name not found');
    }
    return connection;
  }

  Driver getDriver(Connection connection) {
    if (connection is SqliteConnection) {
      return SqliteDriver(connection);
    }
    if (connection is PostgresConnection) {
      return PostgresDriver(connection);
    }
    throw LuexException('Runner not found');
  }

  Grammar getGrammar(Connection connection) {
    if (connection is SqliteConnection) {
      return SqliteGrammar();
    }
    if (connection is PostgresConnection) {
      return PostgresGrammar();
    }
    throw LuexException('Grammar not found');
  }
}
