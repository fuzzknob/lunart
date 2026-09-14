import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // use `signedCookie` middleware
  // If the server doesn't find this middleware while you use `Res.signedCookie` it will throw a runtime error
  app.use(signedCookie(secret: 'my-super-secret'));

  app.post('/set-cookie', (_) {
    return Res.signedCookie('signed-cookie', 'this-is-the-signed-cookie-value');
  });

  app.get('/get-cookie', (req) async {
    final cookie = await req.getSignedCookie('signed-cookie');

    print(cookie);

    return cookie;
  });

  app.get('/get-cookie-with-max-age', (req) async {
    // if the cookie age has expired it returns null
    final cookie = await req.getSignedCookie(
      'signed-cookie',
      maxAge: Duration(days: 30),
    );

    print(cookie);

    return cookie;
  });

  app.delete('/delete-cookie', (_) {
    // you can remove a signed cookie just like a regular cookie
    return Res.removeCookie('signed-cookie');
  });

  app.serve();
}
