import 'package:lucore/lucore.dart';

void main() {
  final router = Router();

  router.group((router) {
    router.get('/', (req) {
      return res.message('Hello from accounts');
    });

    router.get('/deactivate', (req) {
      return res.message('Your account has been deactivated');
    });
  }, prefix: '/accounts');

  Server().serve(router);
}
