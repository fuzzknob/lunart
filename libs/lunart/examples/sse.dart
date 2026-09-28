import 'dart:async';

import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // Text example
  app.get('/', (_) => indexPage);

  app.get('/sse', (_) {
    return Res.sse((sse) {
      print('Sending initial message');
      sse.sendText('Initial Message');

      var i = 1;
      final timer = Timer.periodic(Duration(seconds: 1), (_) {
        sse.sendText(i.toString());
        print('Sending $i');
        i++;
      });

      sse.onClose(() {
        print('connection closed');
        timer.cancel();
      });
    });
  });

  // JSON example
  app.get('/json', (_) => jsonPage);

  app.get('/sse-json', (_) {
    return Res.sse((sse) {
      print('Sending initial message');
      sse.sendJson({'message': 'Initial message'});

      var i = 1;
      final timer = Timer.periodic(Duration(seconds: 1), (_) {
        sse.sendJson({'count': i});
        print('Sending $i');
        i++;
      });

      sse.onClose(() {
        print('connection closed');
        timer.cancel();
      });
    });
  });

  app.serve();
}

const indexPage = '''
<!DOCTYPE html>
<html>
  <head>
      <title>Lunart SSE Example</title>
      <style>
        body {
          background: #000;
          color: #FFF;
          margin: 0;
        }
        main {
          width: 100vw;
          height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
        }
      </style>
  </head>
  <body>
    <main>
      <h1 id="heading"></h1>
    </main>
    <script>
      const heading = document.getElementById('heading')
      const eventSource = new EventSource(`http://10.10.1.11:8000/sse`)

      eventSource.onmessage = (e) => {
        heading.innerText = 'Received: ' + e.data;
      };
    </script>
  </body>
</html>
''';

const jsonPage = '''
<!DOCTYPE html>
<html>
  <head>
      <title>Lunart SSE Example</title>
      <style>
        body {
          background: #000;
          color: #FFF;
          margin: 0;
          font-family: sans-serif;
        }
        main {
          width: 100vw;
          height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
          flex-direction: column;
        }
        h2 {
          margin-bottom: 1px;
        }
        .json-container {
          width: 300px;
          margin: 2rem auto;
          padding: 1.25rem;
          background: #111827;
        }
      </style>
  </head>
  <body>
    <main>
      <h2>Receiving:</h2>
      <div class="json-container">
        <pre><code id="code"></code></pre>
      <div>
    </main>
    <script>
      const codeBlock = document.getElementById('code')
      const eventSource = new EventSource(`http://10.10.1.11:8000/sse-json`)

      eventSource.onmessage = (e) => {
        const data = JSON.parse(e.data);
        codeBlock.innerText = JSON.stringify(data, null, 2);
      };
    </script>
  </body>
</html>
''';
