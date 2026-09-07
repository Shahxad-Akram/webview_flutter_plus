import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:async';

import 'package:flutter/services.dart';

class WebViewControllerPlus extends WebViewController {
  WebViewControllerPlus({
    super.onPermissionRequest,
    PlatformWebViewControllerCreationParams? creationParams,
  }) : super.fromPlatformCreationParams(
          creationParams ?? _defaultCreationParams(),
        );

  /// Default creation params: enable HTML5 inline media playback on iOS
  /// (otherwise it forces fullscreen).
  static PlatformWebViewControllerCreationParams _defaultCreationParams() {
    final params = const PlatformWebViewControllerCreationParams();
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      return WebKitWebViewControllerCreationParams
          .fromPlatformWebViewControllerCreationParams(
        params,
        allowsInlineMediaPlayback: true,
      );
    }
    return params;
  }

  /// Return the height of [WebViewWidget]
  Future<double> get webViewHeight => _getWebViewHeight();

  Future<double> _getWebViewHeight() async {
    String getHeightScript = r"""(function () {
                var element = document.body;
                var height = element.offsetHeight,
                    style = window.getComputedStyle(element)
                return ['top', 'bottom']
                    .map(function (side) {
                        return parseInt(style["margin-" + side]);
                    }).reduce(function (total, side) {
                        return total + side;
                    }, height)
            })();""";

    return double.parse(
        (await super.runJavaScriptReturningResult(getHeightScript)).toString());
  }

  /// Load assets on the local server. [LocalHostServer] must be running.
  ///
  /// [method] must be one of the supported HTTP methods in [LoadRequestMethod].
  ///
  /// If [headers] is not empty, its key-value pairs will be added as the
  /// headers for the request.
  ///
  /// If [body] is not null, it will be added as the body for the request.
  ///
  /// Throws an ArgumentError if [uri] has an empty scheme.
  Future<void> loadFlutterAssetWithServer(
    String uri,
    int port, {
    LoadRequestMethod method = LoadRequestMethod.get,
    Map<String, String> headers = const <String, String>{},
    Uint8List? body,
  }) async {
    return super.loadRequest(Uri.parse('http://localhost:$port/$uri'),
        headers: headers, body: body, method: method);
  }
}
