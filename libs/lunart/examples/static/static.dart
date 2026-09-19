import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart().use(requestLogger);

  // Serves files from the public directory by default
  // Using all method so that the helper can handle both get and head requests
  app.all(
    '*',
    serveStatic(),
  );

  // Serves files from the public-b directory
  app.all(
    'public-b',
    serveStatic(
      path: 'public-b',
    ),
  );

  // Serve a specific JSON file from the jsons directory
  app.all(
    '/jsons/test.json',
    serveStatic(
      path: './jsons/test.json',
    ),
  );

  app.serve();
}
