import 'package:luex/luex.dart';

void main() async {
  // Initialize a SQLite database connection to 'sqlite.db' file
  final db = Database.init(SqliteConnection.file('sqlite.db'));

  // Creating table
  await db.executeRaw('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
    );
  ''');

  // INSERT
  // inserts a single row
  await db.table('users').insert({'name': 'Greg Guy'});

  // inserts multiple rows
  await db.table('users').insertMany([
    {'name': 'Greg Gal'},
    {'name': 'Victor Eee'},
  ]);

  // SELECT
  final allUsers = await db.table('users').all();
  print(allUsers);

  // Runs "SELECT * FROM users WHERE id = 1 LIMIT 1" and gets the first result
  final user = await db.table('users').find(1);
  print(user);

  // Runs "SELECT * FROM users WHERE id = 2" and returns all matching rows
  final user2 = await db.table('users').where('id', 2).get();
  print(user2);

  // UPDATE
  await db.table('users').where('id', 1).update({'name': 'John Doe'});

  // DELETE
  await db.table('users').where('id', 1).delete();
}
