import 'dart:async';

import 'package:lunart/lunart.dart';

void main() {
  final router = Router();

  router.get('/sse', (_) {
    return res().streamEvent((stream) {
      print('sending text message');
      stream.sendText('hello from the other side');

      var i = 0;
      final timer = Timer.periodic(Duration(seconds: 1), (_) {
        print('sending periodic json message');
        stream.sendJson({'message': 'hello $i'}, event: 'custom-event');
        i++;
      });

      stream.onClose(() {
        print('connection closed');
        timer.cancel();
      });
    });
  });

  Server().use(cors()).serve(router, port: 8888);
}
