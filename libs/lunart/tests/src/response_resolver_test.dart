import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/interfaces/to_json.dart';
import 'package:lunart/src/response.dart';
import 'package:lunart/src/response_resolver.dart';

class _MockFile extends Mock implements File {}

class _FakeToJson(final String value) implements ToJson {
  @override
  Map<String, dynamic> toJson() {
    return {'value': value};
  }
}

class _BaseEntity {
  _BaseEntity(this.value);

  final String value;
}

class _SubEntity extends _BaseEntity {
  _SubEntity(super.value);
}

void main() {
  group('ResponseTypeResolver register and getResolver', () {
    test('register returns same resolver instance', () {
      final resolver = ResponseTypeResolver();

      final returned = resolver.register<int>((value) => Res.text('$value'));

      expect(identical(returned, resolver), isTrue);
    });

    test('getResolver returns null for null response', () {
      final resolver = ResponseTypeResolver();

      final registered = resolver.getResolver(null);

      expect(registered, isNull);
    });

    test('getResolver returns registered resolver for matching type', () async {
      final resolver = ResponseTypeResolver()
        ..register<int>((value) => Res.text('int:$value'));

      final registered = resolver.getResolver(7);

      expect(registered, isNotNull);
      final result = await registered!(7);
      expect(result.body, 'int:7');
    });

    test('getResolver uses the latest registered matching resolver', () async {
      final resolver = ResponseTypeResolver()
        ..register<_SubEntity>((value) => Res.text('sub:${value.value}'))
        ..register<_BaseEntity>((value) => Res.text('base:${value.value}'));

      final registered = resolver.getResolver(_SubEntity('x'));

      expect(registered, isNotNull);

      final result = await registered!(_SubEntity('x'));

      expect(result.body, 'base:x');
    });
  });

  group('ResponseTypeResolver resolve', () {
    test('resolve null returns Response with null body', () async {
      final resolver = ResponseTypeResolver();

      final response = await resolver.resolve(null);

      expect(response, isA<Response>());
      expect(response.body, isNull);
    });

    test(
      'resolve returns same Response when autoResolveResponseType is false',
      () async {
        final resolver = ResponseTypeResolver();
        final response = Res.setBody({'original': true})
            .status(HttpStatus.accepted);

        final resolved = await resolver.resolve(response);

        expect(identical(resolved, response), isTrue);
        expect(resolved.body, {'original': true});
        expect(resolved.statusCode, HttpStatus.accepted);
      },
    );

    test(
      'resolve auto resolves nested body when autoResolveResponseType is true',
      () async {
        final resolver = ResponseTypeResolver();
        final response = Res.status(HttpStatus.accepted)
            .header('x-trace', 'yes')
            .any({'ok': true});

        final resolved = await resolver.resolve(response);

        expect(identical(resolved, response), isTrue);
        expect(resolved.body, convert.json.encode({'ok': true}));
        expect(
          resolved.headers['content-type'],
          'application/json; charset=utf-8',
        );
        expect(resolved.headers['x-trace'], 'yes');
        expect(resolved.statusCode, HttpStatus.ok);
        expect(resolved.autoResolveResponseType, isFalse);
      },
    );

    test('uses registered resolver before built-in resolver', () async {
      final resolver = ResponseTypeResolver()
        ..register<String>(
          (value) => Res.status(HttpStatus.created).text('custom:$value'),
        );

      final resolved = await resolver.resolve('hello');

      expect(resolved.statusCode, HttpStatus.created);
      expect(resolved.body, 'custom:hello');
      expect(resolved.headers['content-type'], 'text/plain; charset=utf-8');
    });

    test('resolves html string as html response', () async {
      final resolver = ResponseTypeResolver();

      final response = await resolver.resolve('<div>Hello</div>');

      expect(response.body, '<div>Hello</div>');
      expect(response.headers['content-type'], 'text/html; charset=utf-8');
    });

    test('resolves non-html string as plain text response', () async {
      final resolver = ResponseTypeResolver();

      final response = await resolver.resolve('hello');

      expect(response.body, 'hello');
      expect(response.headers['content-type'], 'text/plain; charset=utf-8');
    });

    test('resolves ToJson object as json response', () async {
      final resolver = ResponseTypeResolver();

      final response = await resolver.resolve(_FakeToJson('one'));

      expect(response.body, convert.json.encode({'value': 'one'}));
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
    });

    test('resolves iterable of ToJson as json array response', () async {
      final resolver = ResponseTypeResolver();

      final response = await resolver.resolve([
        _FakeToJson('one'),
        _FakeToJson('two'),
      ]);

      expect(
        response.body,
        convert.json.encode([
          {'value': 'one'},
          {'value': 'two'},
        ]),
      );
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
    });

    test('resolves Map as json response', () async {
      final resolver = ResponseTypeResolver();

      final response = await resolver.resolve({'name': 'lunart'});

      expect(response.body, convert.json.encode({'name': 'lunart'}));
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
    });

    test('resolves non-ToJson iterable as json response', () async {
      final resolver = ResponseTypeResolver();

      final response = await resolver.resolve([1, 2, 3]);

      expect(response.body, convert.json.encode([1, 2, 3]));
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
    });

    test('resolves File to file stream response and mime type', () async {
      final resolver = ResponseTypeResolver();
      final file = _MockFile();

      when(() => file.path).thenReturn('/tmp/data.json');
      when(() => file.openRead()).thenAnswer(
        (_) => Stream<List<int>>.fromIterable([
          convert.utf8.encode('{"ok":true}'),
        ]),
      );

      final response = await resolver.resolve(file);

      expect(response.headers['Content-Type'], 'application/json');
      expect(response.body, isA<Stream>());
      verifyNever(() => file.openRead(0, 2));
      verify(() => file.openRead()).called(1);
    });

    test('resolves Stream by setting stream as body', () async {
      final resolver = ResponseTypeResolver();
      final stream = Stream<int>.fromIterable([1, 2, 3]);

      final response = await resolver.resolve(stream);

      expect(identical(response.body, stream), isTrue);
    });

    test('falls back to string conversion for unknown object', () async {
      final resolver = ResponseTypeResolver();
      final value = _BaseEntity('fallback');

      final response = await resolver.resolve(value);

      expect(response.body, value.toString());
      expect(response.headers['content-type'], 'text/plain; charset=utf-8');
    });
  });
}
