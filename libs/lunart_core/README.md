# Lunart core

The core of the ecosystem.

### Basic usage
```dart
import 'package:lunart/lunart.dart';

void main() {
  final router = Router();

  router.get('/', (_) => res().message('Hello World'));

  router.post('/posts', (req) async {
    final data = await req.body();
    return res().json(data);
  });

  // Starts server at port 8000 by default
  Server().serve(router);
}
```

For more examples checkout [examples](https://github.com/fuzzknob/lunart/tree/main/libs/lunart_core/examples).
