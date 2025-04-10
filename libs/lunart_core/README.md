# Lunart core (lucore)

The core of the ecosystem.

### Basic usage
```dart
import 'package:lucore/lucore.dart';

void main() {
  final router = Router();

  router.get('/', (_) => res.message('Hello World'));

  router.post('/posts', (req) async {
    final data = await req.body();
    return res.json(data);
  });

  // Starts server at port 8000 by default
  Server().serve(router);
}
```

For more examples checkout [examples](https://github.com/fuzzknob/lunart/tree/main/libs/lunart_core/examples).
