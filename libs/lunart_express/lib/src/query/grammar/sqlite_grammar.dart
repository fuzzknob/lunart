import 'grammar.dart';
import '../query_builder.dart';

class SqliteGrammar extends Grammar {
  @override
  String buildWhereLike(WhereLike where, QueryBuilder query) {
    if (!where.caseSensitive) {
      return super.buildWhereLike(where, query);
    }
    final operator = where.not ? 'NOT GLOB' : 'GLOB';
    return '${where.column} $operator ?';
  }
}
