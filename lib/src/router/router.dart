import 'types.dart';

class Router {
  Router({required this.endPoint});
  final String endPoint;
  final Map<String, Map<String, Map<String, dynamic>>> _routes = {
    "GET": {},
    "POST": {},
    "PUT": {},
    "DELETE": {},
    "PATCH": {},
  };

  Map<String, Map<String, Map<String, dynamic>>> get routes => _routes;

  void get(String path, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["GET"]![path] = {
      'callback': callback,
      'next': next,
    };
  }

  void post(String path, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["POST"]![path] = {
      'callback': callback,
      'next': next,
    };
  }

  void put(String path, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["PUT"]![path] = {
      'callback': callback,
      'next': next,
    };
  }

  void delete(String path, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["DELETE"]![path] = {
      'callback': callback,
      'next': next,
    };
  }

  void patch(String path, RequestHandler callback, [List<RequestHandler>? next]) {
    _routes["PATCH"]![path] = {
      'callback': callback,
      'next': next,
    };
  }
}
