import 'package:lunart/src/exceptions/lunart_exception.dart';

class NotFoundException extends LunartException {
  NotFoundException([String? message])
    : super(statusCode: 404, message: message);
}
