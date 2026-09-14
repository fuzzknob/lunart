import '../lunart.dart';
import '../middlewares/error_handler.dart';
import '../interfaces/plugin.dart';

class BaseLunartPlugin implements Plugin {
  @override
  void plug(Lunart app) {
    app.use(errorHandler);
  }
}
