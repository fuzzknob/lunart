import 'package:lunart/src/exceptions/lunart_exception.dart';
import 'package:lunart/src/server/server.dart';
import 'package:lunart/src/types.dart';

Future<Response> errorHandler(Request request, Next next) async {
  try {
    return await next();
  } on LunartException catch (e) {
    return res()
        .status(e.statusCode)
        .message(e.message ?? 'There was an error');
  } catch (e) {
    print(e);
    return res()
        .status(500)
        .message('There was an error, Please check the logs');
  }
}
