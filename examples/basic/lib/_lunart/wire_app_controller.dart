import 'package:lunart/lunart.dart';

import '../controllers/app_controller.dart';

AppController initializeController() {
  return AppController();
}

Router wireAppController() {
  final controller = AppController();
  final routes = Router();
  final resConverter = ResConverterRegistry();

  routes
      .get('/', (_) => resConverter.convert(controller.index()))
      .get('/about', (_) => resConverter.convert(controller.about()));

  return routes;
}
