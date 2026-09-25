import 'dart:io';
import 'dart:async';

import 'interfaces/to_json.dart';

import 'response.dart';
import 'types.dart';
import 'utils.dart';

class ResponseTypeResolver {
  final _resolvers = <(bool Function(Object?), ResponseResolver)>[];

  ResponseTypeResolver register<T>(ResponseResolver<T> resolver) {
    _resolvers.add(((r) => r is T, (response) => resolver(response as T)));

    return this;
  }

  ResponseResolver? getResolver(Object? response) {
    if (response == null) return null;

    for (final (canResolve, resolver) in _resolvers.reversed) {
      if (canResolve(response)) {
        return resolver;
      }
    }

    return null;
  }

  FutureOr<Response> resolve(Object? response) async {
    if (response == null) return Res.setBody(null);

    if (response is Response) {
      if (response.autoResolveResponseType) {
        final resolved = await resolve(response.body);

        return response.mergeResponse(resolved);
      }

      return response;
    }

    final resolver = getResolver(response);

    if (resolver != null) {
      return await resolver(response);
    }

    if (response is String) return _stringResolver(response);

    if (response is ToJson) return Res.json((response).toJson());

    if (response is Iterable<ToJson>) {
      return Res.json((response).map((e) => e.toJson()).toList());
    }

    if (response is Map) return Res.json(response);

    if (response is Iterable) return Res.json(response);

    if (response is File) return Res.file(response);

    if (response is Stream) return _streamResolver(response);

    return Res.text(response.toString());
  }

  Response _streamResolver(Stream stream) {
    if (stream is Stream<String>) {
      return Res.streamText(stream);
    }

    return Res.stream(stream);
  }

  Response _stringResolver(String response) {
    if (isHtml(response)) {
      return Res.html(response);
    }

    return Res.text(response);
  }
}
