import '../request.dart';

abstract interface class RequestHandler {
  Future handleRequest(Request request);
}
