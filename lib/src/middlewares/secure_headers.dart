import 'package:lunart/src/server/server.dart';
import 'package:lunart/src/types.dart';

Future<Response> secureHeaders(Request request, Next next) async {
  final response = await next();
  return response.addHeaders({
    'X-Content-Type-Options': 'nosniff',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
    'X-Frame-Options': 'SAMEORIGIN',
    'X-XSS-Protection': '0',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  });
}
