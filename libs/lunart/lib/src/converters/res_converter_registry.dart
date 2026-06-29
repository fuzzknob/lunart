import 'dart:io';
import 'package:lucore/lucore.dart';

import '../types.dart';
import '../helpers/log.dart';

class ResConverterRegistry {
  ResConverterRegistry._internal();

  static final ResConverterRegistry _instance =
      ResConverterRegistry._internal();

  factory ResConverterRegistry() => _instance;

  final _converters = <Type, ResponseConverter>{
    String: (response) => res.text(response),
    Map: (response) => res.json(response),
    File: (response) => res.file(response),
  };

  ResConverterRegistry register<T>(ResponseConverter converter) {
    _converters[T] = converter;

    return this;
  }

  FutureOr<Response> convert(dynamic response) {
    if (response == null) return res.setBody(null);

    if (response.runtimeType == Response) return response;

    final converter = _converters[response.runtimeType];

    if (converter == null) {
      Log.warn(
        '${response.runtimeType} don\'t have a appropriate response converter',
      );
      return res.setBody(response);
    }

    return converter(response);
  }
}
