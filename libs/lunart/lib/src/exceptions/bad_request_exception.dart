import 'exception.dart';

class BadRequestException extends LunartException {
  const BadRequestException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 400,
         log: false,
       );
}
