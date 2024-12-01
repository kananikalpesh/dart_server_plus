import 'req.dart';
import 'res.dart';

typedef RequestHandler = Future<Res> Function(Req req, Res res);
