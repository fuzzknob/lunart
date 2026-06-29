import 'package:lunart/lunart.dart';

import 'routes.dart';

void bootstrap() {
  Server().serve(bootstrapRoutes(), port: 8888);
}
