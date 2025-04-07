class LunartException implements Exception {
  const LunartException({this.statusCode = 500, this.message, this.log = true});
  final int statusCode;
  final String? message;
  final bool log;
}
