class LuexException implements Exception {
  const LuexException(this.message, {this.log = true});
  final String? message;
  final bool log;
}
