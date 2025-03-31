class LunartException implements Exception {
  const LunartException({this.statusCode = 500, this.message});
  final int statusCode;
  final String? message;
}
