import 'dart:convert';

import 'package:luex/luex.dart';

void main() async {
  final db = Database.init(SqliteConnection.file('example.db'));

  // setup database with tables and test data
  await setupDatabase(db);

  // Inner Join
  final result =
      await db
          .table('users')
          .select([
            'users.*',
            'posts.id as post_id',
            'posts.title',
            'posts.body',
          ])
          // performs an inner join
          // Note you don't have to specify the join condition operator. By default it is "="
          .join('posts', 'users.id', 'posts.user_id')
          .get();

  // pretty print result
  prettyPrintResult(result);

  // Join with operator
  final result2 =
      await db
          .table('users')
          // If you choice to specify the opeerator or change it you can do so like this
          .join('posts', 'users.id', '=', 'posts.user_id')
          .get();

  prettyPrintResult(result2);

  // Left Join
  final leftJoinResults =
      await db
          .table('users')
          .leftJoin('posts', 'users.id', 'posts.user_id')
          .get();

  prettyPrintResult(leftJoinResults);

  // Right Join
  final rightJoinResults =
      await db
          .table('users')
          .leftJoin('posts', 'users.id', 'posts.user_id')
          .get();

  prettyPrintResult(rightJoinResults);

  // Cross Join
  final crossJoinResult = await db.table('users').crossJoin('posts').get();

  prettyPrintResult(crossJoinResult);

  // Other joins
  // You can also specify the join type in the join function.
  // Note: You'll have to include the operator here
  final otherJoinsResult =
      await db
          .table('users')
          .join('posts', 'users.id', '=', 'posts.user_id', 'FULL OUTER')
          .get();

  prettyPrintResult(otherJoinsResult);
}

Future<void> setupDatabase(Database db) async {
  await db.executeRaw(
    '''
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS posts (
      id INTEGER PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT,
      user_id id INTEGER,

      FOREIGN KEY (user_id) REFERENCES users (id)
    );
  '''.trim(),
  );

  // Inserts and get the id of the inserted row
  final id = await db.table('users').insertGetId({
    'name': 'John Doe',
    'email': 'johndoe@exampl.com',
  });

  await db.table('posts').insertMany([
    {
      'title': 'Lunart Express an orgonic orm',
      'body': 'Lorem ipsum dolar sit',
      'user_id': id,
    },
    {
      'title': 'Morning Motivation',
      'body':
          'Starting the day off right is crucial for a productive and happy life. Take a few minutes each morning to meditate, exercise, or simply enjoy a cup of coffee in peace.',
      'user_id': id,
    },
    {
      'title': 'Weekend Getaway',
      'body':
          'Just got back from an amazing weekend trip to the beach. The sun, sand, and surf were just what I needed to recharge. If you\'re looking for a quick escape, I highly recommend it.',
      'user_id': id,
    },
    {
      'title': 'Book Review',
      'body':
          'I just finished reading a amazing book that I couldn\'t put down. The characters were well-developed, the plot was engaging, and the writing was beautiful.',
      'user_id': id,
    },
  ]);
}

void prettyPrintResult(Object? result) {
  print(JsonEncoder.withIndent(' ').convert(result));
}
