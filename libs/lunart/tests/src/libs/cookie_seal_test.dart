import 'dart:convert';

import 'package:lunart/src/libs/cookie_seal.dart';
import 'package:test/test.dart';

void main() {
  group('CookieSealer', () {
    test('seal and unseal returns original payload', () async {
      final sealer = CookieSealer('secret-key');

      final sealed = await sealer.seal('hello');
      final unsealed = await sealer.unseal(sealed);

      expect(unsealed, 'hello');
    });

    test('seal and unseal preserves unicode payload', () async {
      final sealer = CookieSealer('secret-key');

      final sealed = await sealer.seal('東京タワ🗼');
      final unsealed = await sealer.unseal(sealed);

      expect(unsealed, '東京タワ🗼');
    });

    test('unseal returns null when cookie is tampered', () async {
      final sealer = CookieSealer('secret-key');
      final sealed = await sealer.seal('hello');

      final decoded = utf8.decode(base64Url.decode(sealed));
      final parts = decoded.split('.');
      final signature = parts[2];
      final tamperedSignature = signature.endsWith('a')
          ? '${signature.substring(0, signature.length - 1)}b'
          : '${signature.substring(0, signature.length - 1)}a';
      final tampered = base64Url.encode(
        utf8.encode('${parts[0]}.${parts[1]}.$tamperedSignature'),
      );

      final unsealed = await sealer.unseal(tampered);

      expect(unsealed, isNull);
    });

    test('unseal returns null when secret is different', () async {
      final sealerA = CookieSealer('secret-a');
      final sealerB = CookieSealer('secret-b');

      final sealed = await sealerA.seal('hello');
      final unsealed = await sealerB.unseal(sealed);

      expect(unsealed, isNull);
    });

    test('unseal returns null when maxAge is exceeded', () async {
      final sealer = CookieSealer('secret-key');
      final sealed = await sealer.seal('hello');

      final unsealed = await sealer.unseal(
        sealed,
        maxAge: Duration(milliseconds: -1),
      );

      expect(unsealed, isNull);
    });

    test('unseal returns null for malformed cookie', () async {
      final sealer = CookieSealer('secret-key');

      final unsealed = await sealer.unseal('not-base64-@@');

      expect(unsealed, isNull);
    });
  });
}
