import '../libs/cookie_seal.dart';
import '../request.dart';
import '../response.dart';
import '../types.dart';

Middleware signedCookie({required String secret}) {
  final sealer = CookieSealer(secret);

  return (Request request, Next next) async {
    request.signedCookieParser = sealer.unseal;

    final response = Res.any(await next());

    await Future.wait(
      response.cookies.map((cookie) async {
        if (cookie.signed && !cookie.hasSigned) {
          cookie.value = await sealer.seal(cookie.value);
          cookie.hasSigned = true;
        }
      }),
    );

    return response;
  };
}
