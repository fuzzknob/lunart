import 'connection.dart';

enum PostgresSslMode { disable, require, verifyFull }

class PostgresConnection implements Connection {
  PostgresConnection({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.sslMode = PostgresSslMode.disable,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final PostgresSslMode sslMode;

  factory PostgresConnection.defaults({
    String host = 'localhost',
    int port = 5432,
    String database = 'postgres',
    String username = 'postgres',
    String password = 'postgres',
    PostgresSslMode sslMode = PostgresSslMode.disable,
  }) => PostgresConnection(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
    sslMode: sslMode,
  );
}
