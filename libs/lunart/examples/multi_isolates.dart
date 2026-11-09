import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  app.use(cors());

  app.get('/', (_) async {
    return 'delayed response';
  });

  // Use isolatesMode to run multiple server isolates
  // coreBounded starts one isolate per CPU core
  app.serve(
    port: 3333,
    isolatesMode: .coreBounded,
  );
}
