import 'package:lunart/lunart.dart';

FutureOr<Response> coreMiddleware(Request request, Next next) {
  return next();
}

class HelloMiddleware implements MiddlewareHandler {
  @override
  FutureOr<Response> handle(Request request, Next next) {
    return next();
  }
}

@Controller('')
@Middlewares([HelloMiddleware])
class AppController {
  @Get()
  String index() {
    return 'Welcome home';
  }

  @Get('about')
  String about() {
    return 'This is the about page';
  }
}
