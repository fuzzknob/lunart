import 'package:lunart/src/middlewares/error_handler.dart';
import 'package:lunart/src/server/server.dart';

void basePlugin(Server server) {
  server.use(errorHandler);
}
