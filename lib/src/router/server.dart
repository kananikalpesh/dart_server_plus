import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'req.dart';
import 'res.dart';
import 'types.dart';
import 'router.dart';
import 'package:mime/mime.dart';

class Server {
  HttpServer? _httpServer;
  Function(Object error, Res res)? _errorCallback;

  final Map<String, Map<String, Map<String, dynamic>>> _routes = {
    "GET": {},
    "POST": {},
    "PUT": {},
    "DELETE": {},
    "PATCH": {},
  };

  void get(String endPoint, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["GET"]![endPoint] = {
      'callback': callback,
      'next': next,
    };
  }

  void post(String endPoint, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["POST"]![endPoint] = {
      'callback': callback,
      'next': next,
    };
  }

  void put(String endPoint, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["PUT"]![endPoint] = {
      'callback': callback,
      'next': next,
    };
  }

  void delete(String endPoint, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["DELETE"]![endPoint] = {
      'callback': callback,
      'next': next,
    };
  }

  void patch(String endPoint, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["PATCH"]![endPoint] = {
      'callback': callback,
      'next': next,
    };
  }

  void registerRouters(List<Router> routers) {
    for (Router router in routers) {
      router.routes['GET']!.forEach((key, value) {
        get("${router.endPoint}$key", value['callback'], value['next']);
      });
      router.routes['POST']!.forEach((key, value) {
        post("${router.endPoint}$key", value['callback'], value['next']);
      });
      router.routes['PUT']!.forEach((key, value) {
        put("${router.endPoint}$key", value['callback'], value['next']);
      });
      router.routes['DELETE']!.forEach((key, value) {
        delete("${router.endPoint}$key", value['callback'], value['next']);
      });
      router.routes['PATCH']!.forEach((key, value) {
        patch("${router.endPoint}$key", value['callback'], value['next']);
      });
    }
  }

  Future<void> listen({
    required int port,
    Function()? callback,
    bool shared = false,
    bool v6Only = false,
    int backlog = 0,
    InternetAddress? internetAddress,
  }) async {
    _httpServer = await HttpServer.bind(
      internetAddress ?? InternetAddress.anyIPv4,
      port,
      shared: shared,
      v6Only: v6Only,
      backlog: backlog,
    );
    callback?.call();
    _httpServer?.forEach((element) {
      _handleRequest(element);
    });
  }

  void onError(Function(Object error, Res res) errorCallback) => _errorCallback = errorCallback;

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // request.response.headers.add(HttpHeaders.accessControlAllowOriginHeader, '*');
      // request.response.headers.add(HttpHeaders.accessControlAllowMethodsHeader, 'GET, POST, PUT, DELETE, OPTIONS');
      // request.response.headers.add(HttpHeaders.accessControlAllowHeadersHeader, 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      String requestedMethod = request.method;
      String requestedRoute = request.uri.path;

      Map<String, String> queryParams = request.uri.queryParameters;
      RequestHandler? callback = _routes[requestedMethod]![requestedRoute]?['callback'];

      if (callback != null) {
        List<RequestHandler>? next = _routes[requestedMethod]![requestedRoute]?['next'];
        Map<String, dynamic> body = await _getBodyData(request);
        await callback.call(
          Req(headers: request.headers, body: body, queryParams: queryParams, next: next),
          Res(response: request.response),
        );
      } else {
        String? matchedKey = _findRouteFromPath(requestedRoute, requestedMethod);

        if (matchedKey != null) {
          callback = _routes[requestedMethod]![matchedKey]?['callback'];
          if (callback != null) {
            List<RequestHandler>? next = _routes[requestedMethod]![matchedKey]?['next'];
            Map<String, dynamic> body = await _getBodyData(request);
            Map<String, String> params = _getParams(matchedKey, requestedRoute);
            await callback.call(
              Req(headers: request.headers, body: body, queryParams: queryParams, params: params, next: next),
              Res(response: request.response),
            );
          }
        } else {
          request.response.write("Can not $requestedMethod with $requestedRoute");
          request.response.close();
        }
      }
    } on TypeError catch (e) {
      if (_errorCallback != null) {
        _errorCallback?.call(e, Res(response: request.response));
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(e.toString());
        request.response.close();
      }
    } catch (e) {
      if (_errorCallback != null) {
        _errorCallback?.call(e, Res(response: request.response));
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(e.toString());
        request.response.close();
      }
    }
  }

  Future<Map<String, dynamic>> _getBodyData(HttpRequest element) async {
    Map<String, dynamic> body = {};
    if (element.method != "GET") {
      switch (element.headers.contentType?.mimeType) {
        case "application/json":
          final bodydata = await utf8.decoder.bind(element).join();
          if (bodydata.isNotEmpty) body = jsonDecode(bodydata);
          break;
        case "application/x-www-form-urlencoded":
          final bodydata = await utf8.decoder.bind(element).join();
          if (bodydata.isNotEmpty) body = Uri.splitQueryString(bodydata);
          break;
        case "multipart/form-data":
          body = await _handleFormData(element);
          break;
      }
    }
    return body;
  }

  Map<String, String> _getParams(String route, String path) {
    Map<String, String> params = {};
    List<String> routeStrings = route.split("/");
    List<String> pathStrings = path.split("/");
    for (int i = 0; i < routeStrings.length; i++) {
      if (routeStrings[i].startsWith(":")) {
        params[routeStrings[i].substring(1)] = pathStrings[i];
      }
    }
    return params;
  }

  Future<Map<String, dynamic>> _handleFormData(HttpRequest request) async {
    Map<String, dynamic> formData = {};
    final contentType = request.headers.contentType;
    final transformer = MimeMultipartTransformer(contentType!.parameters['boundary']!);
    final bodyStream = request.cast<List<int>>().transform(transformer);

    await for (final part in bodyStream) {
      final contentDisposition = part.headers['content-disposition'];
      if (contentDisposition != null) {
        final dispositionParams = _parseContentDisposition(contentDisposition);
        final fieldName = dispositionParams['name'];
        final filename = dispositionParams['filename'];
        if (filename != null) {
          final sanitizedFilename = filename.replaceAll(RegExp(r'[^\w\.\-]'), '_');
          final bytesBuilder = BytesBuilder();
          await for (final data in part) {
            bytesBuilder.add(data);
          }
          final fileBytes = bytesBuilder.takeBytes();
          formData[fieldName.toString()] = {
            'fileName': sanitizedFilename,
            'bytes': fileBytes,
          };
        } else if (fieldName != null) {
          final fieldValue = await utf8.decoder.bind(part).join();
          formData[fieldName] = fieldValue;
        }
      }
    }
    return formData;
  }

  Map<String, String> _parseContentDisposition(String contentDisposition) {
    final params = <String, String>{};
    final parts = contentDisposition.split(';');
    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        final key = kv[0].trim();
        final value = kv[1].trim().replaceAll('"', '');
        params[key] = value;
      }
    }
    return params;
  }

  String? _findRouteFromPath(String path, String method) {
    int pathLength = "/".allMatches(path).length;
    List<String> keys = _routes[method]!.keys.where((k) => "/".allMatches(k).length == pathLength).toList();
    if (keys.isNotEmpty) {
      for (String key in keys) {
        String pattern = key.replaceAllMapped(RegExp(r':\w+'), (match) => r'[^/]+');
        pattern = '^$pattern\$';
        if (RegExp(pattern).hasMatch(path)) {
          return key;
        }
      }
    }
    return null;
  }
}
