class const LunartException({
  final int statusCode = 500,
  final bool log = true,
  final String? message,
  final Object? error,
  final Object? context,
  final StackTrace? stackTrace,
}) implements Exception;
