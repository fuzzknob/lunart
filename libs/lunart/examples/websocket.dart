import 'package:lunart/lunart.dart';

void main() {
  // Sample echo server
  Lunart()
    .ws('/echo', (socket) {
      socket.onMessage((message, controller) {
        controller.send(message);
      });
    })
    .serve();
}
