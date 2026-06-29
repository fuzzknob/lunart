import 'package:lunart/lunart.dart';

import 'wire_app_controller.dart';

Router autowiredRoutes() {
  final routes = Router();

  routes.merge(wireAppController());

  return routes;
}
