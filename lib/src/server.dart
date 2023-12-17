import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

class WebViewServer {
  HttpServer? _server;

  ///Closes the server.
  Future<void> close() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }

  ///Starts the server
  Future<int> start() async {
    var completer = Completer<int>();

    runZonedGuarded(() {
      HttpServer.bind('localhost', 0, shared: true).then((server) {
        _server = server;
        server.listen((HttpRequest httpRequest) async {
          List<int> body = [];
          String path = httpRequest.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';
          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
          } catch (e) {
            if (kDebugMode) {
              print('Error: $e');
            }
            httpRequest.response.close();
            return;
          }
          var contentType = ['text', 'html'];
          if (!httpRequest.requestedUri.path.endsWith('/') &&
              httpRequest.requestedUri.pathSegments.isNotEmpty) {
            String? mimeType = lookupMimeType(httpRequest.requestedUri.path,
                headerBytes: body);
            if (mimeType != null) {
              contentType = mimeType.split('/');
            }
          }
          httpRequest.response.headers.contentType =
              ContentType(contentType[0], contentType[1], charset: 'utf-8');
          httpRequest.response.add(body);
          httpRequest.response.close();
        });
        completer.complete(server.port);
      });
    }, (e, stackTrace) {
      if (kDebugMode) {
        print('Error: $e $stackTrace');
      }
    });
    return completer.future;
  }
}
