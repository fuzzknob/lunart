import '../exceptions/lunart_exception.dart';
import '../server/server.dart';
import '../types.dart';

Future<Response> errorHandler(Request request, Next next) async {
  try {
    return await next();
  } on LunartException catch (e, stacktrace) {
    if (e.log) {
      print(e);
      print(stacktrace);
    }
    return res.status(e.statusCode).message(e.message ?? 'There was an error');
  } catch (e, stacktrace) {
    print(e);
    print(stacktrace);
    return res.status(500).message('There was an error, Please check the logs');
  }
}
