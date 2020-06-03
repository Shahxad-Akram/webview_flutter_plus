import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:webview_flutter_plus/src/webview_flutter_plus.dart';

class WebViewFlutterPlusServer {
  HttpServer _server;
  int _port;

  ///Closes the server.
  Future<void> close() async {
    if (this._server != null) {
      await this._server.close(force: true);
      //  print('Server running on http://localhost:$_port closed');
      this._server = null;
    }
  }

  ///Starts the server
  Future<int> start(StreamController<HttpRequest> onRequest,
      {List<CodeInjection> Function() codeInjections}) async {
    var completer = new Completer<int>();
    runZoned(() {
      HttpServer.bind('localhost', 0, shared: true).then((server) {
        //   print('Server running on http://localhost:' + _port.toString());
        this._port = server.port;
        this._server = server;
        server.listen((HttpRequest httpRequest) async {
          onRequest.add(httpRequest);
          var body = List<int>();
          var path = httpRequest.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';
          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
            if (codeInjections.call() != null) {
              String bodyString = String.fromCharCodes(body);
              for (CodeInjection codeInjection in codeInjections.call()) {
                bodyString = bodyString.replaceFirst(
                    codeInjection.from, codeInjection.to);
              }
              body = Uint8List.fromList(bodyString.codeUnits);
            }
          } catch (e) {
            print('Error: $e');
            httpRequest.response.close();
            return;
          }
          var contentType = ['text', 'html'];
          if (!httpRequest.requestedUri.path.endsWith('/') &&
              httpRequest.requestedUri.pathSegments.isNotEmpty) {
            var mimeType = lookupMimeType(httpRequest.requestedUri.path,
                headerBytes: body);
            if (mimeType != null) {
              contentType = mimeType.split('/');
            }
          }
          httpRequest.response.headers.contentType =
              new ContentType(contentType[0], contentType[1], charset: 'utf-8');
          httpRequest.response.add(body);
          httpRequest.response.close();
        });
        completer.complete(_port);
      });
    }, onError: (e, stackTrace) => print('Error: $e $stackTrace'));
    return completer.future;
  }
}
