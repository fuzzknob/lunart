import 'exception.dart';

class ConflictException extends LunartException {
  const ConflictException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 409,
         log: false,
       );
}
