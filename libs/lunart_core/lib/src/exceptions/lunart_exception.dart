class LunartException implements Exception {
  const LunartException({
    this.statusCode = 500,
    this.message,
    this.log = true,
    this.error,
    this.stackTrace,
  });
  final int statusCode;
  final String? message;
  final bool log;
  final Object? error;
  final StackTrace? stackTrace;
}
