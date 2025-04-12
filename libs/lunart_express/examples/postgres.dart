import 'package:luex/luex.dart';

void main() async {
  // Initialize connection with Postgres server with defaults
  // host = 'localhost',
  // port = 5432,
  // database = 'postgres',
  // username = 'postgres',
  // password = 'postgres',
  // sslMode = PostgresSslMode.disable,
  final db = Database.init(PostgresConnection.defaults());

  // Post connection full options
  final db2 = Database.init(
    PostgresConnection(
      database: 'example',
      host: 'example.com',
      port: 5432,
      username: 'example',
      password: 'secure_password',
      sslMode: PostgresSslMode.verifyFull,
    ),
  );

  // SELECT
  final allUsers = await db.table('users').all();
  print(allUsers);

  // Runs "SELECT * FROM users WHERE id = 1 LIMIT 1" and gets the first result
  final user = await db.table('users').find(1);
  print(user);

  // Runs "SELECT * FROM users WHERE id = 2" and returns all matching rows
  final user2 = await db.table('users').where('id', 2).get();
  print(user2);

  // INSERT
  // inserts a single row
  await db.table('users').insert({'name': 'Greg Guy'});

  // inserts multiple rows
  await db2.table('users').insertMany([
    {'name': 'Greg Gal'},
    {'name': 'Victor Eee'},
  ]);

  // UPDATE
  await db.table('users').where('id', 1).update({'name': 'John Doe'});

  // DELETE
  await db.table('users').where('id', 1).delete();
}
