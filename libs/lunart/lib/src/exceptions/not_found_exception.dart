import 'exception.dart';

class NotFoundException extends LunartException {
  const NotFoundException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 404,
         log: false,
       );
}
