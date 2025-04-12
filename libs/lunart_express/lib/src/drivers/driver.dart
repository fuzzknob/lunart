import '../types.dart';

abstract interface class Driver {
  Future<QueryResult> executeSelectQuery(
    String query, [
    List<Object?> parameters = const [],
  ]);

  Future<void> executeInsertQuery(
    String query, [
    List<Object?> parameters = const [],
  ]);

  Future<Object> executeInsertGetIdQuery(
    String query, [
    List<Object?> parameters = const [],
  ]);

  Future<void> executeUpdateQuery(
    String query, [
    List<Object?> parameters = const [],
  ]);

  Future<void> executeDeleteQuery(
    String query, [
    List<Object?> parameters = const [],
  ]);
}
