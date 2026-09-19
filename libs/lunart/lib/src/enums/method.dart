enum Method {
  get,
  head,
  post,
  put,
  delete,
  connect,
  options,
  trace,
  patch,
  all;

  String get value {
    return switch (this) {
      (Method.get) => 'GET',
      (Method.head) => 'HEAD',
      (Method.post) => 'POST',
      (Method.put) => 'PUT',
      (Method.delete) => 'DELETE',
      (Method.connect) => 'CONNECT',
      (Method.options) => 'OPTIONS',
      (Method.trace) => 'TRACE',
      (Method.patch) => 'PATCH',
      (Method.all) => 'ALL',
    };
  }

  @override
  String toString() {
    return value;
  }

  factory Method.fromString(String method) {
    return switch (method.toUpperCase()) {
      'GET' => Method.get,
      'HEAD' => Method.head,
      'POST' => Method.post,
      'PUT' => Method.put,
      'DELETE' => Method.delete,
      'CONNECT' => Method.connect,
      'OPTIONS' => Method.options,
      'TRACE' => Method.trace,
      'PATCH' => Method.patch,
      _ => throw Exception('Unknown method => $method'),
    };
  }
}
