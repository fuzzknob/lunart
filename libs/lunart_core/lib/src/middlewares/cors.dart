import 'dart:io';

import '../enums/method.dart';
import '../server/server.dart';
import '../types.dart';

Middleware cors({
  List<String> origins = const [],
  List<String> allowHeaders = const [],
  List<Method> allowMethods = Method.values,
  List<String> exposeHeaders = const [],
  int? maxAge,
  bool credentials = false,
}) {
  return (Request request, Next next) async {
    final headers = <String, String>{};
    final requestOrigin = request.headers['origin']?.first ?? '';

    if (origins.isEmpty) {
      headers['Access-Control-Allow-Origin'] = '*';
    } else if (origins.contains(requestOrigin)) {
      headers['Access-Control-Allow-Origin'] = requestOrigin;
      headers['Vary'] = 'Origin';
    }

    if (credentials) {
      headers['Access-Control-Allow-Credentials'] = 'true';
    }

    if (exposeHeaders.isNotEmpty) {
      headers['Access-Control-Expose-Headers'] = exposeHeaders.join(',');
    }

    if (request.method != Method.options) {
      final response = await next();
      response.addHeaders(headers);
      return response;
    }
    final response = Response();

    if (maxAge != null) {
      headers['Access-Control-Max-Age'] = maxAge.toString();
    }

    if (allowMethods.isNotEmpty) {
      headers['Access-Control-Allow-Methods'] = allowMethods.join(',');
    }

    if (allowHeaders.isNotEmpty) {
      headers['Access-Control-Allow-Headers'] = allowHeaders.join(',');
    } else {
      final requestHeaders = request.headers['access-control-request-headers'];
      if (requestHeaders != null && requestHeaders.isNotEmpty) {
        headers['Access-Control-Allow-Headers'] = requestHeaders.join(',');
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
