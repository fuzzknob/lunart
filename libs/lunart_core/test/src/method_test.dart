import 'package:lucore/src/enums/method.dart';

import 'package:test/test.dart';

void main() {
  group('method', () {
    test('parses correct method', () {
      expect(Method.fromString('GET'), Method.get);
      expect(Method.fromString('HEAD'), Method.head);
      expect(Method.fromString('POST'), Method.post);
      expect(Method.fromString('PUT'), Method.put);
      expect(Method.fromString('DELETE'), Method.delete);
      expect(Method.fromString('CONNECT'), Method.connect);
      expect(Method.fromString('OPTIONS'), Method.options);
      expect(Method.fromString('TRACE'), Method.trace);
      expect(Method.fromString('PATCH'), Method.patch);
    });

    test('has correct method value', () {
      expect(Method.get.value, 'GET');
      expect(Method.head.value, 'HEAD');
      expect(Method.post.value, 'POST');
      expect(Method.put.value, 'PUT');
      expect(Method.delete.value, 'DELETE');
      expect(Method.connect.value, 'CONNECT');
      expect(Method.options.value, 'OPTIONS');
      expect(Method.trace.value, 'TRACE');
      expect(Method.patch.value, 'PATCH');
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
