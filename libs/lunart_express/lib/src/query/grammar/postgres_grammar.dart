import '../query_builder.dart';
import 'grammar.dart';

class PostgresGrammar extends Grammar {
  @override
  String postBuildQuery(String query) {
    var parameterCount = 0;
    return query.replaceAllMapped('--<PARAMETER>', (_) {
      parameterCount++;
      return '\$$parameterCount';
    });
  }

  @override
  String buildInsertGetIdQuery(QueryBuilder query, Map<String, Object?> value) {
    final sql = buildInsertQuery(query, [value]);
    return '$sql RETURNING ${query.identityColumn}';
  }
}
