import '../exceptions/lunart_exception.dart';
import '../server/server.dart';
import '../types.dart';

enum _LogType { log, error }

void _printLog(String message, [_LogType type = _LogType.log]) {
  final prefix =
      type == _LogType.error
          ? '\x1B[31m[ERROR]\x1B[0m'
          : '\x1B[32m[LOG]\x1B[0m';
  print('$prefix $message');
}

Future<Response> logger(Request request, Next next) async {
  final watch = Stopwatch()..start();
  final startTime = DateTime.now();
  try {
    final response = await next();
    final statusCode = response.statusCode;
    _printLog(
      '${startTime.toString()} [${request.method}] ${request.path} $statusCode took ${watch.elapsed.inMilliseconds}ms',
      statusCode == 500 ? _LogType.error : _LogType.log,
    );
    return response;
  } on LunartException catch (e) {
    _printLog(
      '${startTime.toString()} [${request.method}] ${request.path} ${e.statusCode} took ${watch.elapsed.inMilliseconds}ms',
      e.statusCode == 500 ? _LogType.error : _LogType.log,
    );
    rethrow;
  } catch (e) {
    _printLog(
      '${startTime.toString()} [${request.method}] ${request.path} took ${watch.elapsed.inMilliseconds}ms',
      _LogType.error,
    );
    rethrow;
  } finally {
    watch.stop();
  }
}
