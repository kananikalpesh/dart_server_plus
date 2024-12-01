import 'dart:io';
import 'types.dart';
import 'res.dart';

class Req {
  Req({
    required this.headers,
    this.body = const {},
    this.params = const {},
    this.queryParams = const {},
    List<RequestHandler>? next,
  }) : _next = next;
  final Map body;
  final Map params;
  final Map<String, String> queryParams;
  final HttpHeaders headers;
  final Map data = {};
  int middlewareIndex = 0;
  final List<RequestHandler>? _next;

  Future<Res> next(Res res) async {
    if (_next == null) throw "Middleware not defined or missing.";
    if (_next.isEmpty || _next.length == middlewareIndex) throw "Next middleware not defined or missing.";
    RequestHandler callBack = _next[middlewareIndex];
    middlewareIndex += 1;
    return await callBack(this, res);
  }
}
