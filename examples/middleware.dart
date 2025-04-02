import 'dart:async';

import 'package:lunart/lunart.dart';

FutureOr<Response> globalMiddleware(Request req, Next next) {
  print('-> global middleware');
  return next();
}

FutureOr<Response> routeMiddleware1(Request req, Next next) {
  print('--> route middleware 1');
  return next();
}

FutureOr<Response> routeMiddleware2(Request req, Next next) {
  print('---> route middleware 2');
  return next();
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
  final router = Router();

  router.get('/', (_) {
    print('----> route handler');

    return res();

    // Add route middleware directly in the route
  }, middlewares: [routeMiddleware1, routeMiddleware2]);

  // Add global middleware directly in the server
  Server().use(globalMiddleware).serve(router);
}
