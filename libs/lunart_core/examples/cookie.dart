import 'package:lunart_core/lunart_core.dart';

void main() {
  final router = Router();

  router.post('/set-cookie', (_) {
    return res().cookie('remember-me', 'true');
  });

  router.get('/get-cookie', (req) {
    final rememberMe = req.getCookie('remember-me');

    print(rememberMe);

    return res().ok();
  });

  router.delete('/delete-cookie', (_) {
    return res().removeCookie('remember-cookie');
  });

  router.post('/set-cookie-with-option', (_) {
    return res().cookie(
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

  Server().serve(router);
}
