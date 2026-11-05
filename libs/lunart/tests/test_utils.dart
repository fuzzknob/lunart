import 'dart:typed_data';

import 'package:lunart/src/cookie.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/enums/method.dart';

Request buildRequest({
  String path = '/',
  Method method = .get,
  String routerPath = '',
  Map<String, String> headers = const {},
  Map<String, String> queries = const {},
  Map<String, LunartCookie> cookies = const {},
}) {
  return Request(
    path: path,
    method: method,
    headers: headers,
    queries: queries,
    cookies: cookies,
    getRawBody: () async => Uint8List.fromList([]),
  )..routerPath = routerPath.isNotEmpty ? routerPath : path;
}
