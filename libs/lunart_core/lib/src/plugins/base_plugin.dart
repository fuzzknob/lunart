import '../middlewares/error_handler.dart';
import '../server/server.dart';

void basePlugin(Server server) {
  server.use(errorHandler);
}
