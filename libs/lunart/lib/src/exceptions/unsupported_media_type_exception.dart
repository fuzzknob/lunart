import 'exception.dart';

class UnsupportedMediaTypeException extends LunartException {
  const UnsupportedMediaTypeException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 415,
         log: false,
       );
}
