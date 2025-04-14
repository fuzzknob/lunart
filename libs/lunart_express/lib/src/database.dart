import 'query/query_builder.dart';
import 'exceptions/luex_exception.dart';
import 'connection/connection.dart';

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
    String? connection,
    String identityColumn = 'id',
  }) {
    final conn = getConnection(connection);
    final runner = getRunner(connectionInstance: conn);

    return QueryBuilder(
      table: table,
      identityColumn: identityColumn,
      grammar: conn.grammar,
      runner: runner,
    );
  }

  Future<void> executeRaw(String query, {String? connection}) {
    final conn = getConnection(connection);
    return conn.driver.executeRawQuery(query);
  }

  Runner getRunner({String? connection, Connection? connectionInstance}) {
    final conn = connectionInstance ?? getConnection(connection);
    return Runner(conn.driver);
  }

  Connection getConnection([String? name]) {
    name ??= 'default';
    final connection = connections[name];
    if (connection == null) {
      throw LuexException('Connection $name not found');
    }
    return connection;
  }
}
