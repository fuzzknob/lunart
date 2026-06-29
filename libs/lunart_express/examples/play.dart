import 'package:luex/luex.dart';

void main() async {
  final db = Database.init(SqliteConnection.file('test.db'));

  // final watch = Stopwatch()..start();
  // await db.table('users').insertMany([
  //   {'id': 1, 'name': 'Daniel'},
  //   {'id': 1, 'name': 'Daniel'},
  //   {'id': 1, 'name': 'Daniel'},
  // ]);

  // await db.table('users').update({'name': 'Gregg'});

  // await db.table('users').whereIn('id', [4, 6, 9]).delete();
  // await db.table('users').delete();

  // print(watch.elapsed.inMilliseconds);
  // final id = await db.table('users').insertGetId({'name': 'Sam'}) as int;
  // print(id);

  // final result = await db.table('users').all();
  // print(result);
  await db.table('users').where('id', 2).orWhereNotBetween('age', 2, 3).get();
}
