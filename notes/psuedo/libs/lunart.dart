class WebsocketController {
  void send(String message) {}
}

class WebsocketEvent {
  void open(Function(WebsocketController) handler) {}

  void listen(String name, Function(WebsocketController) handler) {
    //
  }

  void listenAll(Function(WebsocketController) handler) {}
}

abstract class Plugin {}

class Lunart {
  Lunart use(Plugin plugin) {
    return this;
  }

  Lunart get(String path, Function handler) {
    print(path);

    return this;
  }

  Lunart post(String path, Function handler) {
    print(path);

    return this;
  }

  Lunart ws(String path, WebsocketEvent Function(WebsocketEvent) handler) {
    return this;
  }

  void serve({int port = 3000}) {
    //
  }
}
