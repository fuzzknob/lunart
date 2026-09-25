import 'dart:async';

import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  app.get('/', (req) async* {
    final sentence =
        'This sentence will be streamed to the client one word at a time very slowly.';

    for (final word in sentence.split(' ')) {
      yield '$word ';
      await Future.delayed(Duration(milliseconds: 500));
    }
  });

  app.serve();
}
