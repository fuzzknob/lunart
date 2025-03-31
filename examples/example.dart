import 'dart:io';

import 'package:lunart/lunart.dart';

void main() {
  final router = Router();

  router.get('/', (_) {
    return res().message('This is a message to the world');
  });

  router.get('/cookie', (req) async {
    final cookieValue = await req.getSignedCookie('signed-cookie');
    return res().json({'cookie-value': cookieValue});
  });

  router.post('/cookie', (_) {
    return res()
        .signedCookie('signed-cookie', 'This is the value for signed cookie')
        .message('tis is a massage');
  });

  router.get('/remove-cookie', (_) {
    return res().removeCookie('signed-cookie').message('removed cookie');
  });

  router.get('/users/:username', (req) {
    return res().json(req.parameters);
  });

  router.get('/some/*/hello', (_) {
    return res().message('Hello');
  });

  router.post('/posts', (req) async {
    final body = await req.body();
    return res().json(body);
  });

  router.get('/exception', (req) {
    throw LunartException(
      statusCode: HttpStatus.unauthorized,
      message: 'This is an expected exception',
    );
  });

  router.get('/redirect', (req) => res().redirect('/'));

  final apiRoutes = Router.nest('/api')..merge(postsRoutes());

  router.merge(apiRoutes);

  Server()
      .use(logger)
      .use(signedCookie(secret: 'This is the secret for the cookie'))
      .use(cors())
      .serve(router, port: 8888);
}

Router postsRoutes() {
  final routes = Router.nest('/posts');

  routes.get(
    '/',
    (req) => res().message('This is a get request to the post route'),
  );

  routes.post(
    '/',
    (req) => res().message('This is post request to the post route'),
  );

  return routes;
}
