import 'package:luex/luex.dart';

void main() async {
  final db = Database.init(SqliteConnection.file('sqlite.db'));

  // SELECT
  final allUsers = await db.table('users').all();
  print(allUsers); // gets all users

  final user = await db.table('users').find(1);
  print(user); // get user with id 1

  final user2 = await db.table('users').where('id', 2).get();
  print(user2); // get user with id 2

  // INSERT
  await db.table('users').insert({'name': 'Greg Guy'}); // inserts a single row

  // inserts a multiple rows
  await db.table('users').insertMany([
    {'name': 'Greg Gal'},
    {'name': 'Victor Eee'},
  ]);

  // UPDATE
  await db.table('users').where('id', 1).update({'name': 'John Doe'});

  // DELETE
  await db.table('users').where('id', 1).delete();
}
