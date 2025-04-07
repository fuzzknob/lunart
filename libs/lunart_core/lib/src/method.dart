enum Method {
  get,
  post,
  put,
  patch,
  head,
  options,
  delete;

  String get value {
    return switch (this) {
      (Method.get) => 'GET',
      (Method.post) => 'POST',
      (Method.put) => 'PUT',
      (Method.patch) => 'PATCH',
      (Method.delete) => 'DELETE',
      (Method.head) => 'HEAD',
      (Method.options) => 'OPTIONS',
    };
  }

  @override
  String toString() {
    return value;
  }

  static Method fromString(String method) {
    return switch (method.toUpperCase()) {
      'GET' => Method.get,
      'POST' => Method.post,
      'PUT' => Method.put,
      'PATCH' => Method.patch,
      'DELETE' => Method.delete,
      'HEAD' => Method.head,
      'OPTIONS' => Method.options,
      _ => throw Exception('Unknown method => $method'),
    };
  }
}
