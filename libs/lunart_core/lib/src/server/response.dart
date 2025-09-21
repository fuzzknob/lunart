part of 'server.dart';

class Response {
  int _statusCode = HttpStatus.ok;
  Object _body = '';
  Map<String, Object> _headers = {};
  Function(HttpResponse, Response)? _hijacker;
  List<LunartCookie> cookies = [];

  int get statusCode => _statusCode;
  Map<String, Object> get headers => _headers;
  Object get body => _body;

  bool get hasHijacked => _hijacker != null;

  Response status(int statusCode) {
    _statusCode = statusCode;
    return this;
  }

  Response header(String name, Object value) {
    _headers[name] = value;
    return this;
  }

  Response addHeaders(Map<String, Object> headers) {
    _headers = {..._headers, ...headers};
    return this;
  }

  /// Sets the content-type header to application/json
  Response json(dynamic body) {
    _body = convert.json.encode(body);
    header('content-type', 'application/json');
    return this;
  }

  /// Sends a json response with a message property
  /// ```json
  /// {
  ///   "message": "the message"
  /// }
  /// ```
  Response message(String message) => json({'message': message});

  /// Sets the content-type header to text/html
  Response html(String html) {
    _body = html;
    header('content-type', 'text/html');
    return this;
  }

  Response text(String text) {
    _body = text;
    header('content-type', 'text/plain');
    return this;
  }

  Response redirect(String url, [int statusCode = HttpStatus.found]) {
    _statusCode = statusCode;
    header('Location', url);
    return this;
  }

  Response cookie(
    String name,
    String value, {
    bool httpOnly = true,
    bool secure = true,
    String path = '/',
    String? domain,
    DateTime? expires,
    Duration? maxAge,
    SameSite? sameSite,
  }) {
    cookies.add(
      LunartCookie(
        name: name,
        value: value,
        httpOnly: httpOnly,
        secure: secure,
        domain: domain,
        path: path,
        expires: expires,
        maxAge: maxAge,
        sameSite: sameSite,
      ),
    );
    return this;
  }

  Response signedCookie(
    String name,
    String value, {
    bool httpOnly = true,
    bool secure = true,
    String path = '/',
    String? domain,
    DateTime? expires,
    Duration? maxAge,
    SameSite? sameSite,
  }) {
    cookies.add(
      LunartCookie(
        name: name,
        value: value,
        httpOnly: httpOnly,
        secure: secure,
        domain: domain,
        path: path,
        expires: expires,
        maxAge: maxAge,
        sameSite: sameSite,
        signed: true,
      ),
    );
    return this;
  }

  Response removeCookie(String name) {
    cookies.add(
      LunartCookie(name: name, value: '', maxAge: Duration(seconds: 0)),
    );
    return this;
  }

  /// Hijacks the response.
  /// The hijacker is responsible to write and close the http response
  Response hijack(Function(HttpResponse, Response) hijacker) {
    _hijacker = hijacker;
    return this;
  }

  Response streamEvent(void Function(sse.SSEStream) cb) =>
      sse.streamEvent(cb, this);

  Response stream(Stream stream) {
    _body = stream;

    return this;
  }

  Future<Response> file(File file) async {
    header(
      'Content-Type',
      await getMimeType(file) ?? 'application/octet-stream',
    );

    return stream(file.openRead());
  }

  Response notFound() => status(HttpStatus.notFound);

  Response ok() => status(HttpStatus.ok);

  Response created() => status(HttpStatus.ok);

  Response internalServerError() => status(HttpStatus.internalServerError);

  Response forbidden() => status(HttpStatus.forbidden);

  Response unauthorized() => status(HttpStatus.unauthorized);

  Response badRequest() => status(HttpStatus.badRequest);

  Response noContent() => status(HttpStatus.noContent);
}

Response get res => Response();
