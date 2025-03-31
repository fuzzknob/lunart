import 'dart:convert';
import 'dart:isolate';
import 'package:crypto/crypto.dart';

class CookieSealer {
  CookieSealer(String secret) {
    _hmac = Hmac(sha256, utf8.encode(secret));
  }
  late final Hmac _hmac;

  Future<String> seal(String data) async {
    final payload =
        '${DateTime.now().millisecondsSinceEpoch}.${_base64Encode(data)}';
    final signature = await _createSignature(payload);
    final cookie = '$payload.$signature';
    return _base64Encode(cookie);
  }

  Future<String?> unseal(String cookie, {Duration? maxAge}) async {
    try {
      final parts = _base64Decode(cookie).split('.');
      final timestamp = int.parse(parts[0]);
      final data = parts[1];
      final signature = parts[2];

      if (maxAge != null) {
        final expiration = timestamp + maxAge.inMilliseconds;
        if (DateTime.now().millisecondsSinceEpoch > expiration) return null;
      }
      final expectedSignature = await _createSignature('$timestamp.$data');
      if (signature != expectedSignature) return null;
      return _base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  Future<String> _createSignature(String payload) async {
    return Isolate.run(() {
      final digest = _hmac.convert(utf8.encode(payload));
      return digest.toString();
    });
  }

  String _base64Encode(String data) {
    return base64Url.encode(utf8.encode(data));
  }

  String _base64Decode(String payload) {
    return utf8.decode(base64Url.decode(payload));
  }
}
