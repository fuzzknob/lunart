import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  app.post('/set-cookie', (_) {
    return Res.cookie('remember-me', 'true');
  });

  app.get('/get-cookie', (req) {
    final rememberMe = req.getCookie('remember-me');

    return rememberMe;
  });

  app.delete('/delete-cookie', (_) {
    return Res.removeCookie('remember-cookie');
  });

  app.post('/set-cookie-with-option', (_) {
    return Res.cookie(
      'remember-options',
      'true',
      domain: 'http://example.com',
      expires: DateTime.now().add(Duration(days: 30)),
      httpOnly: true,
      maxAge: Duration(days: 30),
      path: '/',
      sameSite: SameSite.strict,
      secure: true,
    );
  });

  app.serve();
}
