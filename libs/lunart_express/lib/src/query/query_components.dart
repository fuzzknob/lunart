part of 'query_builder.dart';

abstract interface class Where {}

class BasicWhere implements Where {
  const BasicWhere({
    required this.column,
    required this.operator,
    required this.value,
    this.conjunction = 'AND',
    this.not = false,
  });

  final String column;
  final String operator;
  final Object value;
  final String conjunction;
  final bool not;

  @override
  String toString() {
    return 'BasicWhere($column, $operator, $value, $conjunction, $not)';
  }
}

class WhereLike implements Where {
  const WhereLike({
    required this.column,
    required this.value,
    this.conjunction = 'AND',
    this.caseSensitive = false,
    this.not = false,
  });

  final String column;
  final Object value;
  final String conjunction;
  final bool caseSensitive;
  final bool not;
}

class WhereIn implements Where {
  const WhereIn({
    required this.column,
    required this.values,
    this.conjunction = 'AND',
    this.not = false,
  });

  final String column;
  final String conjunction;
  final List<Object> values;
  final bool not;
}

abstract interface class OrderBy {}

class DirectionalOrderBy implements OrderBy {
  const DirectionalOrderBy({required this.column, required this.direction});

  final String column;
  final String direction;
}

class RawOrderBy implements OrderBy {
  const RawOrderBy(this.sql);

  final String sql;
}
