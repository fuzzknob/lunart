import 'exception.dart';

class UnprocessableEntityException extends LunartException {
  const UnprocessableEntityException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 422,
         log: false,
       );
}
