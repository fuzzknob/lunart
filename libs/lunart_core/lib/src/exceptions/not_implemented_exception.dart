import '../exceptions/lunart_exception.dart';

class NotImplementedException extends LunartException {
  const NotImplementedException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 501,
         message: message,
         log: true,
         error: error,
         stackTrace: stackTrace,
       );
}
