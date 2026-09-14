import 'package:lunart/lunart.dart';

Object? globalMiddleware(Request req, Next next) async {
  print('-> global middleware');
  final response = await next();
  print('-> global middleware');

  return response;
}

Object? routeMiddleware1(Request req, Next next) async {
  print('--> route middleware 1');
  final response = await next();
  print('--> route middleware 1');

  return response;
}

Object? routeMiddleware2(Request req, Next next) async {
  print('---> route middleware 2');
  final response = await next();
  print('---> route middleware 2');

  return response;
}

// The console output of the this setup will look something like this:
// -> global middleware
// --> route middleware 1
// ---> route middleware 2
// ----> route handler
// ---> route middleware 2
// --> route middleware 1
// -> global middleware
void main() {
  final app = Lunart();

  // Add global middleware by calling `use` on the app instance
  app.use(globalMiddleware);

  app.get('/', (_) {
    print('----> route handler');

    return 'Hello';
    // Add route middleware directly in the route
  }, middlewares: [routeMiddleware1, routeMiddleware2]);

  app.serve();
}
