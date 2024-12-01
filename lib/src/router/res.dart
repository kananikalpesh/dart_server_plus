import 'dart:convert';
import 'dart:io';

class Res {
  final HttpResponse _response;
  Res({required HttpResponse response}) : _response = response;
  int _statusCode = 200;

  Res status(int statusCode) {
    _statusCode = statusCode;
    return this;
  }

  set statusCode(int statusCode) => _statusCode = statusCode;

  Future<Res> write(Object object, {int? statusCode}) async {
    try {
      _response.statusCode = statusCode ?? _statusCode;
      _response.headers.contentType = ContentType.html;
      _response.write(object);
      await _response.close();
      return this;
    } catch (e) {
      rethrow;
    }
  }

  Future<Res> sendText(String data, {int? statusCode}) async {
    try {
      _response.statusCode = statusCode ?? _statusCode;
      _response.headers.contentType = ContentType.text;
      _response.write(data);
      await _response.close();
      return this;
    } catch (e) {
      rethrow;
    }
  }

  Res json(Object object, {int? statusCode, Object? Function(Object? nonEncodable)? toEncodable}) {
    // try {
    //   _response.statusCode = statusCode ?? _statusCode;
    //   _response.headers.contentType = ContentType.json;
    //   _response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
    //   final jsonString = jsonEncode(object, toEncodable: toEncodable);
    //   final jsonBytes = utf8.encode(jsonString);
    //   final gzipEncoder = GZipEncoder();
    //   final gzippedBytes = gzipEncoder.encode(jsonBytes) ?? [];

    //   _response.add(gzippedBytes);
    //   await _response.close();
    // } catch (_) {
    //   rethrow;
    // }

    _response.statusCode = statusCode ?? _statusCode;
    _response.headers.contentType = ContentType.json;
    _response.headers.set("Content-Encoding", "gzip");
    try {
      final gzipSink = gzip.encoder.startChunkedConversion(_response);
      gzipSink.add(utf8.encode(jsonEncode(object, toEncodable: toEncodable)));
      gzipSink.close();
      return this;
    } catch (e) {
      rethrow;
    }
  }
}
