import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

class WebviewPlusBuilder extends StatefulWidget {
  final WebViewWidget Function(WebViewPlusController controler) webViewWidget;
  final Function(WebViewPermissionRequest request)? onPermissionRequest;
  const WebviewPlusBuilder(this.webViewWidget,
      {super.key, this.onPermissionRequest});

  @override
  State<WebviewPlusBuilder> createState() => _WebviewPlusBuilderState();
}

class _WebviewPlusBuilderState extends State<WebviewPlusBuilder> {
  final _server = _WebviewServer();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _server.start(),
      builder: (BuildContext context, AsyncSnapshot<int> snap) {
        if (snap.hasData && !snap.hasError) {
          if (kDebugMode) {
            print("Server started on port: ${snap.data}");
          }
          return widget.webViewWidget(WebViewPlusController._(snap.data!,
              onPermissionRequest: widget.onPermissionRequest));
        } else {
          if (kDebugMode) {
            print('Error: ${snap.error}');
          }
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class WebViewPlusController extends WebViewController {
  final int _port;

  WebViewPlusController._(
    this._port, {
    super.onPermissionRequest,
  });

  get port => _port;

  /// Return the height of [WebViewPlus]
  Future<Object> getWebViewHeight() async {
    String getHeightScript = r"""
        getWebviewFlutterPlusHeight();
        function getWebviewFlutterPlusHeight() {
            var element = document.body;
            var height = element.offsetHeight,
                style = window.getComputedStyle(element)
            return ['top', 'bottom']
                .map(function (side) {
                    return parseInt(style["margin-" + side]);
                })
                .reduce(function (total, side) {
                    return total + side;
                }, height)
              }""";
    return await super.runJavaScriptReturningResult(getHeightScript);
  }

  Future<void> loadAssetOnServer(
    String uri, {
    LoadRequestMethod method = LoadRequestMethod.get,
    Map<String, String> headers = const <String, String>{},
    Uint8List? body,
  }) async {
    return super.loadRequest(Uri.parse('http://localhost:$_port/$uri'),
        headers: headers, body: body, method: method);
  }
}

class _WebviewServer {
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
