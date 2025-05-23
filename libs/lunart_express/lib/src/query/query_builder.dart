import '../runner.dart';
import '../exceptions/luex_exception.dart';
import '../types.dart';
import 'grammar/grammar.dart';

part 'query_components.dart';

class QueryBuilder {
  QueryBuilder({
    required this.runner,
    required this.table,
    required this.grammar,
    this.identityColumn = 'id',
  });

  final Runner runner;
  final String table;
  final Grammar grammar;
  final String identityColumn;

  final List<Join> joins = [];
  final List<Where> whereList = [];
  final List<OrderBy> orderBys = [];
  List<String>? columns;
  final queryBindings = QueryBindings();
  int? sqlLimit;

  String sql = '';

  QueryBuilder select(List<String> columns) {
    this.columns = columns;
    return this;
  }

  QueryBuilder where(String column, Object operatorOrValue, [Object? value]) {
    return _where(
      column: column,
      operatorOrValue: operatorOrValue,
      value: value,
    );
  }

  QueryBuilder orWhere(String column, Object operatorOrValue, [Object? value]) {
    return _where(
      column: column,
      operatorOrValue: operatorOrValue,
      value: value,
      conjunction: 'OR',
    );
  }

  QueryBuilder whereNot(
    String column,
    Object operatorOrValue, [
    Object? value,
  ]) {
    return _where(
      column: column,
      operatorOrValue: operatorOrValue,
      value: value,
      not: true,
    );
  }

  QueryBuilder orWhereNot(
    String column,
    Object operatorOrValue, [
    Object? value,
  ]) {
    return _where(
      column: column,
      operatorOrValue: operatorOrValue,
      value: value,
      conjunction: 'OR',
      not: true,
    );
  }

  QueryBuilder whereLike(
    String column,
    String value, {
    bool caseSensitive = false,
  }) {
    return _whereLike(
      column: column,
      value: value,
      caseSensitive: caseSensitive,
    );
  }

  QueryBuilder orWhereLike(
    String column,
    String value, {
    bool caseSensitive = false,
  }) {
    return _whereLike(
      column: column,
      value: value,
      caseSensitive: caseSensitive,
      conjunction: 'OR',
    );
  }

  QueryBuilder whereNotLike(
    String column,
    String value, {
    bool caseSensitive = false,
  }) {
    return _whereLike(
      column: column,
      value: value,
      caseSensitive: caseSensitive,
      not: true,
    );
  }

  QueryBuilder orWhereNotLike(
    String column,
    String value, {
    bool caseSensitive = false,
  }) {
    return _whereLike(
      column: column,
      value: value,
      caseSensitive: caseSensitive,
      conjunction: 'OR',
      not: true,
    );
  }

  QueryBuilder whereIn(String column, List<Object> values) {
    return _whereIn(column: column, values: values);
  }

  QueryBuilder orWhereIn(String column, List<Object> values) {
    return _whereIn(column: column, values: values, conjunction: 'OR');
  }

  QueryBuilder whereNotIn(String column, List<Object> values) {
    return _whereIn(column: column, values: values, not: true);
  }

  QueryBuilder orWhereNotIn(String column, List<Object> values) {
    return _whereIn(
      column: column,
      values: values,
      not: true,
      conjunction: 'OR',
    );
  }

  QueryBuilder whereBetween(String column, Object min, Object max) {
    return _whereBetween(column: column, min: min, max: max);
  }

  QueryBuilder orWhereBetween(String column, Object min, Object max) {
    return _whereBetween(column: column, min: min, max: max, conjunction: 'OR');
  }

  QueryBuilder whereNotBetween(String column, Object min, Object max) {
    return _whereBetween(column: column, min: min, max: max, not: true);
  }

  QueryBuilder orWhereNotBetween(String column, Object min, Object max) {
    return _whereBetween(
      column: column,
      min: min,
      max: max,
      conjunction: 'OR',
      not: true,
    );
  }

  QueryBuilder join(
    String table,
    String leftColumn,
    String operatorOrRightColumn, [
    String? rightColumn,
    String type = 'INNER',
  ]) {
    var operator = '=';
    if (rightColumn == null) {
      rightColumn = operatorOrRightColumn;
    } else {
      operator = operatorOrRightColumn;
    }
    joins.add(
      ComparativeJoin(
        table: table,
        leftColumn: leftColumn,
        operator: operator,
        rightColumn: rightColumn,
        type: type.toUpperCase(),
      ),
    );
    return this;
  }

  QueryBuilder leftJoin(
    String table,
    String leftColumn,
    String operatorOrRightColumn, [
    String? rightColumn,
  ]) {
    return join(table, leftColumn, operatorOrRightColumn, rightColumn, 'LEFT');
  }

  QueryBuilder rightJoin(
    String table,
    String leftColumn,
    String operatorOrRightColumn, [
    String? rightColumn,
  ]) {
    return join(table, leftColumn, operatorOrRightColumn, rightColumn, 'RIGHT');
  }

  QueryBuilder crossJoin(String table) {
    joins.add(CrossJoin(table));
    return this;
  }

  QueryBuilder orderBy(String column, [String direction = 'ASC']) {
    direction = direction.toUpperCase();

    if (!['ASC', 'DESC'].contains(direction)) {
      throw LuexException(
        '$direction is not a valid direction for ordering. Try out orderByRaw',
      );
    }

    orderBys.add(DirectionalOrderBy(column: column, direction: direction));
    return this;
  }

  QueryBuilder orderByRaw(String sql) {
    orderBys.add(RawOrderBy(sql));
    return this;
  }

  QueryBuilder random([String seed = '']) {
    return orderByRaw(grammar.buildRandom(seed));
  }

  Future<QueryResult?> all([List<String>? columns]) => get(columns);

  Future<QueryResult?> get([List<String>? columns]) async {
    if (columns != null) {
      this.columns = columns;
    }
    sql = grammar.buildSelectQuery(this);
    return runner.runSelectQuery(this);
  }

  Future<Row?> first([List<String>? columns]) async {
    final result = await limit(1).get(columns);
    return result?.first;
  }

  Future<Row?> find(Object identity, [List<String>? columns]) {
    return where(identityColumn, identity).first(columns);
  }

  QueryBuilder limit(int value) {
    sqlLimit = value;
    return this;
  }

  Future<void> insert(Map<String, Object?> value) async {
    return insertMany([value]);
  }

  Future<void> insertMany(List<Map<String, Object?>> values) {
    queryBindings.values = values;
    sql = grammar.buildInsertQuery(this, values);
    return runner.runInsertQuery(this);
  }

  Future<Object?> insertGetId(Map<String, Object?> value) {
    queryBindings.values = [value];
    sql = grammar.buildInsertGetIdQuery(this, value);
    return runner.runInsertGetIdQuery(this);
  }

  Future<void> update(Map<String, Object?> value) {
    queryBindings.values = [value];
    sql = grammar.buildUpdateQuery(this, value);
    return runner.runUpdateQuery(this);
  }

  Future<void> delete() {
    sql = grammar.buildDeleteQuery(this);
    return runner.runDeleteQuery(this);
  }

  QueryBuilder _where({
    required String column,
    required Object operatorOrValue,
    Object? value,
    String conjunction = 'AND',
    bool not = false,
  }) {
    var operator = '=';
    if (value == null) {
      value = operatorOrValue;
    } else {
      if (operatorOrValue.runtimeType != String) {
        throw LuexException('Invalid sql comparison operator type');
      }
      operator = operatorOrValue as String;
    }

    operator = operator.toUpperCase();

    if (!grammar.operators.contains(operator)) {
      throw LuexException('Unknown comparison operator "$operator"');
    }

    queryBindings.where.add(value);

    whereList.add(
      BasicWhere(
        column: column,
        operator: operator,
        value: value,
        conjunction: conjunction,
        not: not,
      ),
    );
    return this;
  }

  QueryBuilder _whereLike({
    required String column,
    required Object value,
    bool caseSensitive = false,
    String conjunction = 'AND',
    bool not = false,
  }) {
    queryBindings.where.add(value);
    whereList.add(
      WhereLike(
        column: column,
        value: value,
        caseSensitive: caseSensitive,
        conjunction: conjunction,
        not: not,
      ),
    );
    return this;
  }

  QueryBuilder _whereIn({
    required String column,
    required List<Object> values,
    String conjunction = 'AND',
    bool not = false,
  }) {
    queryBindings.where.addAll(values);
    whereList.add(
      WhereIn(
        column: column,
        values: values,
        conjunction: conjunction,
        not: not,
      ),
    );
    return this;
  }

  QueryBuilder _whereBetween({
    required String column,
    required Object min,
    required Object max,
    String conjunction = 'AND',
    bool not = false,
  }) {
    // order matters here
    queryBindings.where.addAll([min, max]);
    whereList.add(
      WhereBetween(
        column: column,
        min: min,
        max: max,
        conjunction: conjunction,
        not: not,
      ),
    );
    return this;
  }
}

class QueryBindings {
  List<Object> select = [];
  List<Object> where = [];
  List<Map<String, Object?>> values = [];
}
