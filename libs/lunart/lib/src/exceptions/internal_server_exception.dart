import 'exception.dart';

class InternalServerException extends LunartException {
  const InternalServerException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 500,
         log: true,
       );
}
