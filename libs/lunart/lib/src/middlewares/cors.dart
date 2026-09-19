import 'dart:io';

import '../enums/method.dart';
import '../request.dart';
import '../response.dart';
import '../types.dart';

Middleware cors({
  List<String> origins = const [],
  List<String> allowHeaders = const [],
  List<Method> allowMethods = const [
    Method.all,
  ],
  List<String> exposeHeaders = const [],
  int? maxAge,
  bool credentials = false,
}) {
  return (Request request, Next next) async {
    final headers = <String, String>{};

    if (credentials) {
      headers['Access-Control-Allow-Credentials'] = 'true';
    }

    if (exposeHeaders.isNotEmpty) {
      headers['Access-Control-Expose-Headers'] = exposeHeaders.join(',');
    }
    final requestOrigin = request.headers['origin'] ?? '';

    if (origins.isEmpty) {
      headers['Access-Control-Allow-Origin'] = '*';
    } else if (origins.contains(requestOrigin)) {
      headers['Access-Control-Allow-Origin'] = requestOrigin;
      headers['Vary'] = 'Origin';
    }

    if (request.method != Method.options) {
      var response = Res.any(await next());

      response.addHeaders(headers);

      return response;
    }

    final response = Response();

    if (maxAge != null) {
      headers['Access-Control-Max-Age'] = maxAge.toString();
    }

    if (allowMethods.contains(Method.all)) {
      headers['Access-Control-Allow-Methods'] = [
        Method.options,
        Method.get,
        Method.head,
        Method.post,
        Method.put,
        Method.patch,
        Method.delete,
      ].join(',');
    } else if (allowMethods.isNotEmpty) {
      headers['Access-Control-Allow-Methods'] = allowMethods.join(',');
    }

    if (allowHeaders.isNotEmpty) {
      headers['Access-Control-Allow-Headers'] = allowHeaders.join(',');
    } else {
      final requestHeaders = request.headers['access-control-request-headers'];

      if (requestHeaders != null && requestHeaders.isNotEmpty) {
        headers['Access-Control-Allow-Headers'] = requestHeaders;
      }
    }

    if (headers['Vary'] != null &&
        headers['Access-Control-Allow-Headers'] != null) {
      headers['Vary'] = '${headers['Vary']},Access-Control-Request-Headers';
    } else {
      headers['Vary'] = 'Access-Control-Request-Headers';
    }

    response.addHeaders(headers);

    return response.status(HttpStatus.noContent);
  };
}
