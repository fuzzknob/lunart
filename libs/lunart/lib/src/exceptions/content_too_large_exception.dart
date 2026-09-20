import 'exception.dart';

class ContentTooLargeException extends LunartException {
  ContentTooLargeException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 413,
         log: false,
       );
}
