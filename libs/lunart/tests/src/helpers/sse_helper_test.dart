import 'dart:async';

import 'package:test/test.dart';

import 'package:lunart/src/helpers/sse_helper.dart';

void main() {
  group('SSEHelper', () {
    test('sendText formats single-line message', () async {
      final helper = SSEHelper();

      final eventFuture = helper.stream.first;
      helper.sendText('hello');

      final event = await eventFuture;

      expect(event, 'data: hello\n\n\n');
      await helper.close();
    });

    test(
      'sendText formats multi-line message into multiple data lines',
      () async {
        final helper = SSEHelper();

        final eventFuture = helper.stream.first;
        helper.sendText('line1\nline2');

        final event = await eventFuture;

        expect(event, 'data: line1\ndata: line2\n\n\n');
        await helper.close();
      },
    );

    test('sendText includes optional event, id, and retry fields', () async {
      final helper = SSEHelper();

      final eventFuture = helper.stream.first;
      helper.sendText('payload', event: 'message', id: '42', retry: 1500);

      final event = await eventFuture;

      expect(
        event,
        'event: message\ndata: payload\nid: 42\nretry: 1500\n\n\n',
      );
      await helper.close();
    });

    test(
      'sendJson serializes json payload and emits through text format',
      () async {
        final helper = SSEHelper();

        final eventFuture = helper.stream.first;
        helper.sendJson({'ok': true});

        final event = await eventFuture;

        expect(event, 'data: {"ok":true}\n\n\n');
        await helper.close();
      },
    );

    test(
      'close closes stream and subsequent sendText throws StateError',
      () async {
        final helper = SSEHelper();

        final doneFuture = expectLater(helper.stream, emitsDone);

        await helper.close();
        await doneFuture;

        expect(() => helper.sendText('after-close'), throwsStateError);
      },
    );

    test(
      'onClose callback runs when stream subscription is canceled',
      () async {
        final helper = SSEHelper();
        final callbackCompleter = Completer<void>();

        helper.onClose(() {
          if (!callbackCompleter.isCompleted) {
            callbackCompleter.complete();
          }
        });

        final subscription = helper.stream.listen((_) {});

        await subscription.cancel();
        await callbackCompleter.future;
      },
    );
  });
}
