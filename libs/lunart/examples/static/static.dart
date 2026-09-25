import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // Serves files from the public directory by default
  app.plug(StaticPlugin(route: '*'));

  // Serves files from the public-b directory
  app.plug(StaticPlugin(route: '/public-b', path: './public-b'));

  // Serve a specific JSON file from the jsons directory
  // The path can be either be a directory or a file
  app.plug(
    StaticPlugin(
      route: '/test.json',
      path: './jsons/test.json',
    ),
  );

  app.serve();
}
