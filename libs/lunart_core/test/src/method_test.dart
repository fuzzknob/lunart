import 'package:lucore/src/method.dart';

import 'package:test/test.dart';

void main() {
  group('method', () {
    test('parses correct method', () {
      expect(Method.fromString('GET'), Method.get);
      expect(Method.fromString('POST'), Method.post);
      expect(Method.fromString('PUT'), Method.put);
      expect(Method.fromString('PATCH'), Method.patch);
      expect(Method.fromString('DELETE'), Method.delete);
      expect(Method.fromString('HEAD'), Method.head);
      expect(Method.fromString('OPTIONS'), Method.options);
    });

    test('has correct method value', () {
      expect(Method.get.value, 'GET');
      expect(Method.post.value, 'POST');
      expect(Method.put.value, 'PUT');
      expect(Method.patch.value, 'PATCH');
      expect(Method.delete.value, 'DELETE');
      expect(Method.head.value, 'HEAD');
      expect(Method.options.value, 'OPTIONS');
    });

    test('throws an error if given invalid string to parse', () {
      var hasThrown = false;

      try {
        Method.fromString('some random string');
      } catch (_) {
        hasThrown = true;
      }

      expect(hasThrown, isTrue);
    });
  });
}
