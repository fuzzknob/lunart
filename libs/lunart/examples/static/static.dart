import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart().use(requestLogger);

  // Serves files from the public directory by default
  app.get(
    '*',
    serveStatic(),
  );

  // Serves files from the public-b directory
  app.get(
    'public-b',
    serveStatic(
      path: 'public-b',
    ),
  );

  // Serve a specific JSON file from the jsons directory
  app.get(
    '/jsons/test.json',
    serveStatic(
      path: './jsons/test.json',
    ),
  );

  app.serve();
}
