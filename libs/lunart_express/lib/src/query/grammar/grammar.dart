import '../query_builder.dart';

abstract class Grammar {
  final List<String> operators = [
    '=',
    '<',
    '>',
    '<=',
    '>=',
    '<>',
    '!=',
    'LIKE',
    'NOT LIKE',
    'ILIKE',
    '&',
    '|',
    '<<',
    '>>',
  ];

  String buildSelectQuery(QueryBuilder query) {
    // SELECT
    final List<String> queryComponents = ['SELECT'];

    // COLUMNS
    queryComponents.add(buildSelectColumns(query));

    // FROM
    queryComponents.add('FROM ${query.table}');

    // WHERE
    queryComponents.add(buildWhere(query));

    // LIMIT
    queryComponents.add(buildLimit(query));

    return postBuildQuery(
      queryComponents.where((component) => component.isNotEmpty).join(' '),
    );
  }

  String buildSelectColumns(QueryBuilder query) {
    final columns = query.columns;
    if (columns == null || columns.isEmpty) {
      return '*';
    }
    return columns.join(', ');
  }

  String buildWhere(QueryBuilder query) {
    final statements = <String>[];

    if (query.whereList.isEmpty) {
      return '';
    }

    String trimConjunction(String conjunction, String statement) {
      if (statements.isNotEmpty) {
        return '$conjunction $statement';
      }
      return statement;
    }

    for (final where in query.whereList) {
      if (where is BasicWhere) {
        statements.add(
          trimConjunction(where.conjunction, buildBasicWhere(where, query)),
        );
        continue;
      }
      if (where is WhereLike) {
        statements.add(
          trimConjunction(where.conjunction, buildWhereLike(where, query)),
        );
      }
      if (where is WhereIn) {
        statements.add(
          trimConjunction(where.conjunction, buildWhereIn(where, query)),
        );
      }
    }

    return 'WHERE ${statements.join(' ')}';
  }

  String buildBasicWhere(BasicWhere where, QueryBuilder query) {
    final statement =
        '${where.column} ${where.operator} ${_buildParameter(where.value)}';
    if (where.not) {
      return 'NOT $statement';
    }
    return statement;
  }

  String buildWhereLike(WhereLike where, QueryBuilder query) {
    final operator = where.not ? 'NOT LIKE' : 'LIKE';
    return '${where.column} $operator ${_buildParameter(where.value)}';
  }

  String buildWhereIn(WhereIn where, QueryBuilder query) {
    final values = where.values.map((v) => _buildParameter(v)).join(', ');
    final operator = where.not ? 'NOT IN' : 'IN';
    return '${where.column} $operator ($values)';
  }

  String buildLimit(QueryBuilder query) {
    final limit = query.sqlLimit;
    if (limit == null) return '';
    return 'LIMIT $limit';
  }

  String buildInsertQuery(
    QueryBuilder query,
    List<Map<String, Object?>> values,
  ) {
    if (values.isEmpty) {
      return 'INSERT INTO ${query.table} DEFAULT VALUES';
    }

    final columns = values.first.keys.toSet();

    // final placeholder =
    //     '(${columns.map((v) => _buildParameter(v)).join(', ')})';
    final val = values
        .map((value) => '(${value.values.map(_buildParameter).join(', ')})')
        .join(', ');

    final sql =
        'INSERT INTO ${query.table} (${columns.join(', ')}) VALUES $val';

    return postBuildQuery(sql);
  }

  String buildInsertGetIdQuery(QueryBuilder query, Map<String, Object?> value) {
    return buildInsertQuery(query, [value]);
  }

  String buildUpdateQuery(QueryBuilder query, Map<String, Object?> value) {
    final columns = value.entries
        .map((entry) => '${entry.key} = ${_buildParameter(entry.value)}')
        .join(',');
    final where = buildWhere(query);
    final sql = 'UPDATE ${query.table} SET $columns $where'.trim();
    return postBuildQuery(sql);
  }

  String buildDeleteQuery(QueryBuilder query) {
    final where = buildWhere(query);
    final sql = 'DELETE FROM ${query.table} $where'.trim();
    return postBuildQuery(sql);
  }

  String buildRandom(String seed) => 'RANDOM()';

  String postBuildQuery(String query) {
    return query.replaceAll('--<PARAMETER>', '?');
  }

  String _buildParameter(Object? value) => '--<PARAMETER>';
}
