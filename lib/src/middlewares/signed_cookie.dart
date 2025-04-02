import 'package:lunart/src/libs/cookie_seal.dart';
import 'package:lunart/src/server/server.dart';
import 'package:lunart/src/types.dart';

Middleware signedCookie({required String secret}) {
  final sealer = CookieSealer(secret);
  return (Request request, Next next) async {
    request.signedCookieParser = sealer.unseal;
    final response = await next();
    await Future.wait(
      response.cookies.map((cookie) async {
        cookie.value = await sealer.seal(cookie.value);
        cookie.hasSigned = true;
      }),
    );
    return response;
  };
}
