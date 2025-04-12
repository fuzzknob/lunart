import 'drivers/driver.dart';
import 'query/query_builder.dart';
import 'types.dart';

class Runner {
  Runner(this.driver);

  final Driver driver;

  Future<QueryResult> runSelectQuery(QueryBuilder query) async {
    final result = await driver.executeSelectQuery(
      query.sql,
      buildParameters(query.queryBindings, ['select', 'where']),
    );
    return result;
  }

  Future<void> runInsertQuery(QueryBuilder query) {
    return driver.executeInsertQuery(
      query.sql,
      buildParameters(query.queryBindings, ['values']),
    );
  }

  Future<Object> runInsertGetIdQuery(QueryBuilder query) {
    return driver.executeInsertGetIdQuery(
      query.sql,
      buildParameters(query.queryBindings, ['values']),
    );
  }

  Future<void> runUpdateQuery(QueryBuilder query) {
    return driver.executeUpdateQuery(
      query.sql,
      buildParameters(query.queryBindings, ['values', 'where']),
    );
  }

  Future<void> runDeleteQuery(QueryBuilder query) {
    return driver.executeDeleteQuery(
      query.sql,
      buildParameters(query.queryBindings, ['where']),
    );
  }

  List<Object?> buildParameters(QueryBindings bindings, List<String> includes) {
    final parameters = <Object?>[];

    for (final type in includes) {
      if (type == 'select') {
        parameters.addAll(bindings.select);
      }

      if (type == 'values') {
        for (final value in bindings.values) {
          parameters.addAll(value.values);
        }
      }

      if (type == 'where') {
        parameters.addAll(bindings.where);
      }
    }

    return parameters;
  }
}
