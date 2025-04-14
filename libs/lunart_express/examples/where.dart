import 'package:luex/luex.dart';

void main() async {
  // Initialize a SQLite database connection to 'sqlite.db' file
  final db = Database.init(SqliteConnection.file('sqlite.db'));

  // Basic where clause.
  // This query is equivalent to SELECT * FROM users WHERE id = 1
  // Note: here we don't need to specify the operator "=". By default Querybuilder adds "=" operator if not specified
  final results = await db.table('users').where('id', 1).get();
  print(results);

  // Where clause with operator
  final results2 = await db.table('users').where('age', '>', 20).get();
  print(results2);

  // Chaining where clause
  // SELECT * FROM users WHERE lastName = 'Doe' AND age > 20
  final results3 =
      await db
          .table('users')
          .where('lastName', 'Doe')
          .where('age', '>', 20)
          .get();

  print(results3);

  // Chaining or where clause
  // SELECT * FROM users WHERE lastName = 'Doe' OR age > 20
  final results4 =
      await db
          .table('users')
          .where('lastName', 'Doe')
          .orWhere('age', '>', 20)
          .get();

  print(results4);

  // Where like query
  // SELECT * FROM users WHERE lastName LIKE %Do%
  final results5 = await db.table('users').whereLike('lastName', '%Do%').get();

  print(results5);

  // Where in query
  // SELECT * FROM users WHERE id IN (1, 2, 4)
  final results6 = await db.table('users').whereIn('id', [1, 2, 4]).get();
  print(results6);

  //  Where between query
  // SELECT * FROM users WHERE id BETWEEN 30 AND 40
  final results7 = await db.table('users').whereBetween('age', 30, 40).get();
  print(results7);
}
