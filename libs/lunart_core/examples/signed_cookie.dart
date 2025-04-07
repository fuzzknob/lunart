import 'package:lucore/lucore.dart';

void main() {
  final router = Router();

  router.post('/set-cookie', (_) {
    return res().signedCookie('remember-me', 'true');
  });

  router.get('/get-cookie', (req) async {
    final rememberMe = await req.getSignedCookie('remember-me');

    print(rememberMe);

    return res();
  });

  router.get('/get-cookie-with-max-age', (req) async {
    // if the cookie age has expired it returns null
    final rememberMe = await req.getSignedCookie(
      'remember-me',
      maxAge: Duration(days: 30),
    );

    print(rememberMe);

    return res();
  });

  router.delete('/delete-cookie', (_) {
    // you can remove a signed cookie just like a regular cookie
    return res().removeCookie('remember-cookie');
  });

  // use signed cookie middleware
  // If the server doesn't find this middleware it will throw an runtime error
  Server()
      .use(signedCookie(secret: 'pass your very strong secret here'))
      .serve(router);
}
