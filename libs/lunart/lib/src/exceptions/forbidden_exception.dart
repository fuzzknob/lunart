import 'exception.dart';

class ForbiddenException extends LunartException {
  const ForbiddenException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 403,
         log: false,
       );
}
