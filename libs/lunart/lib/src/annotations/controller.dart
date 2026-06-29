import 'package:lunart/src/middleware_handler.dart';

class Controller {
  const Controller([this.path = '', this.middlwares = const []]);

  final String path;
  final List<MiddlewareHandler> middlwares;
}
