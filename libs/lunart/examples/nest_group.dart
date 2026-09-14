import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // A different way to do nested routes
  app.group(
    (router) {
      // all routes inside this group will be prefixed with '/accounts'
      // and will use the accountsMiddleware
      router.get('/', (req) => 'Hello from accounts');

      router.get(
        '/deactivate',
        (req) => 'Your account has been deactivated',
      );
    },
    prefix: '/accounts',
    middlewares: [accountsMiddleware],
  );

  app.serve();
}

Object? accountsMiddleware(Request req, Next next) {
  print('accountsMiddleware: ${req.path}');

  return next();
}
