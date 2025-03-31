# Lunart

An ergonomic server side library.

> ⚠️ Lunart is still in active development. Some features are still missing and some features might not be there yet.

### Basic usage
```dart
import 'package:lunart/lunart.dart';

void main() {
  final route = Route();

  route.get('/', (_) => res().message('Hello World'))

  route.post('/posts', (req) async {
    final data = await req.body();
    return res().json(data);
  });

  Server().serve(route, port: 8000);
}
```

For more examples checkout [examples](https://github.com/fuzzknob/lunart/tree/main/examples).
