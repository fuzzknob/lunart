import 'libs/lunart.dart';

void main() {
  final lunart = Lunart();

  lunart
      .get('/', () {
        return 'something';
      })
      .post('/', () {
        return {'message': 'This is the message'};
      })
      .ws('/', (controller) {
        controller.listen('message', (ws) {});

        controller.listenAll((ws) {
          ws.send('Message Received');
        });

        return controller;
      });

  lunart.serve(port: 3000);
}
