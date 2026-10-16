import 'dart:io';

import '../response.dart';

abstract interface class ResponseThief {
  Future writeResponse(HttpResponse httpResponse, Response response);
}
