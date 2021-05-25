import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Optional callback invoked when a web view is first created. [controller] is
/// the [WebViewController] for the created web view.
typedef void WebViewPlusCreatedCallback(
  WebViewPlusController controller,
);

/// A web view widget for showing html content.
///
/// There is a known issue that on iOS 13.4 and 13.5, other flutter widgets covering
/// the `WebView` is not able to block the `WebView` from receiving touch events.
/// See https://github.com/flutter/flutter/issues/53490.
class WebViewPlus extends StatefulWidget {
  /// If not null invoked once the web view is created.
  final WebViewPlusCreatedCallback? onWebViewCreated;

  /// Which gestures should be consumed by the web view.
  ///
  /// It is possible for other gesture recognizers to be competing with the web view on pointer
  /// events, e.g if the web view is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The web view will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// When this set is empty or null, the web view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// The initial URL to load.
  final String? initialUrl;

  /// Whether Javascript execution is enabled.
  final JavascriptMode javascriptMode;

  /// The set of [JavascriptChannel]s available to JavaScript code running in the web view.
  ///
  /// For each [JavascriptChannel] in the set, a channel object is made available for the
  /// JavaScript code in a window property named [JavascriptChannel.name].
  /// The JavaScript code can then call `postMessage` on that object to send a message that will be
  /// passed to [JavascriptChannel.onMessageReceived].
  ///
  /// For example for the following JavascriptChannel:
  ///
  /// ```dart
  /// JavascriptChannel(name: 'Print', onMessageReceived: (JavascriptMessage message) { print(message.message); });
  /// ```
  ///
  /// JavaScript code can call:
  ///
  /// ```javascript
  /// Print.postMessage('Hello');
  /// ```
  ///
  /// To asynchronously invoke the message handler which will print the message to standard output.
  ///
  /// Adding a new JavaScript channel only takes affect after the next page is loaded.
  ///
  /// Set values must not be null. A [JavascriptChannel.name] cannot be the same for multiple
  /// channels in the list.
  ///
  /// A null value is equivalent to an empty set.
  final Set<JavascriptChannel>? javascriptChannels;

  /// A delegate function that decides how to handle navigation actions.
  ///
  /// When a navigation is initiated by the WebView (e.g when a user clicks a link)
  /// this delegate is called and has to decide how to proceed with the navigation.
  ///
  /// See [NavigationDecision] for possible decisions the delegate can take.
  ///
  /// When null all navigation actions are allowed.
  ///
  /// Caveats on Android:
  ///
  ///   * Navigation actions targeted to the main frame can be intercepted,
  ///     navigation actions targeted to subframes are allowed regardless of the value
  ///     returned by this delegate.
  ///   * Setting a navigationDelegate makes the WebView treat all navigations as if they were
  ///     triggered by a user gesture, this disables some of Chromium's security mechanisms.
  ///     A navigationDelegate should only be set when loading trusted content.
  ///   * On Android WebView versions earlier than 67(most devices running at least Android L+ should have
  ///     a later version):
  ///     * When a navigationDelegate is set pages with frames are not properly handled by the
  ///       webview, and frames will be opened in the main frame.
  ///     * When a navigationDelegate is set HTTP requests do not include the HTTP referer header.
  final NavigationDelegate? navigationDelegate;

  /// Controls whether inline playback of HTML5 videos is allowed on iOS.
  ///
  /// This field is ignored on Android because Android allows it by default.
  ///
  /// By default `allowsInlineMediaPlayback` is false.
  final bool allowsInlineMediaPlayback;

  /// Invoked when a page starts loading.
  final PageStartedCallback? onPageStarted;

  /// Invoked when a page has finished loading.
  ///
  /// This is invoked only for the main frame.
  ///
  /// When [onPageFinished] is invoked on Android, the page being rendered may
  /// not be updated yet.
  ///
  /// When invoked on iOS or Android, any Javascript code that is embedded
  /// directly in the HTML has been loaded and code injected with
  /// [WebViewController.evaluateJavascript] can assume this.
  final PageFinishedCallback? onPageFinished;

  /// Invoked when a page is loading.
  final PageLoadingCallback? onProgress;

  /// Invoked when a web resource has failed to load.
  ///
  /// This can be called for any resource (iframe, image, etc.), not just for
  /// the main page.
  final WebResourceErrorCallback? onWebResourceError;

  /// Controls whether WebView debugging is enabled.
  ///
  /// Setting this to true enables [WebView debugging on Android](https://developers.google.com/web/tools/chrome-devtools/remote-debugging/).
  ///
  /// WebView debugging is enabled by default in dev builds on iOS.
  ///
  /// To debug WebViews on iOS:
  /// - Enable developer options (Open Safari, go to Preferences -> Advanced and make sure "Show Develop Menu in Menubar" is on.)
  /// - From the Menu-bar (of Safari) select Develop -> iPhone Simulator -> <your webview page>
  ///
  /// By default `debuggingEnabled` is false.
  final bool debuggingEnabled;

  /// A Boolean value indicating whether horizontal swipe gestures will trigger back-forward list navigations.
  ///
  /// This only works on iOS.
  ///
  /// By default `gestureNavigationEnabled` is false.
  final bool gestureNavigationEnabled;

  /// The value used for the HTTP User-Agent: request header.
  ///
  /// When null the platform's webview default is used for the User-Agent header.
  ///
  /// When the [WebView] is rebuilt with a different `userAgent`, the page reloads and the request uses the new User Agent.
  ///
  /// When [WebViewController.goBack] is called after changing `userAgent` the previous `userAgent` value is used until the page is reloaded.
  ///
  /// This field is ignored on iOS versions prior to 9 as the platform does not support a custom
  /// user agent.
  ///
  /// By default `userAgent` is null.
  final String? userAgent;

  /// Which restrictions apply on automatic media playback.
  ///
  /// This initial value is applied to the platform's webview upon creation. Any following
  /// changes to this parameter are ignored (as long as the state of the [WebView] is preserved).
  ///
  /// The default policy is [AutoMediaPlaybackPolicy.require_user_action_for_all_media_types].
  final AutoMediaPlaybackPolicy initialMediaPlaybackPolicy;

  /// Creates a new web view.
  ///
  /// The web view can be controlled using a `WebViewControllerPlus` that is passed to the
  /// `onWebViewCreated` callback once the web view is created.
  ///
  /// The `javascriptMode` and `autoMediaPlaybackPolicy` parameters must not be null.
  const WebViewPlus({
    Key? key,
    this.onWebViewCreated,
    this.initialUrl,
    this.javascriptMode = JavascriptMode.disabled,
    this.javascriptChannels,
    this.navigationDelegate,
    this.gestureRecognizers,
    this.onPageStarted,
    this.onPageFinished,
    this.onProgress,
    this.onWebResourceError,
    this.debuggingEnabled = false,
    this.gestureNavigationEnabled = false,
    this.userAgent,
    this.initialMediaPlaybackPolicy =
        AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
    this.allowsInlineMediaPlayback = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WebViewPlusState();
}

class WebViewPlusController {
  final WebViewController _webViewController;
  final int? _port;

  WebViewPlusController._(this._webViewController, this._port);

  /// Return port of local running server.
  int? get serverPort => _port;

  /// Return [WebViewController] from [WebView]

  WebViewController get webViewController => _webViewController;

  /// Return the height of [WebViewPlus]
  Future<double> getHeight() async {
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
    return double.parse(
        await _webViewController.evaluateJavascript(getHeightScript));
  }

  /// Loads Web content hardcoded in string.
  Future<void> loadString(String code,
      {Map<String, String>? headers,
      String? mimeType = 'text/html',
      Encoding? encoding,
      Map<String, String>? parameters,
      bool base64 = false}) {
    return this.loadUrl(
        Uri.dataFromString(code,
                base64: base64,
                parameters: parameters,
                mimeType: mimeType,
                encoding: encoding ?? Encoding.getByName('utf-8'))
            .toString(),
        headers: headers);
  }

  Future<void> loadUrl(String url, {Map<String, String>? headers}) {
    bool _validURL = Uri.parse(url).isAbsolute;
    if (_validURL) {
      return _webViewController.loadUrl(url, headers: headers);
    } else {
      return _loadAsset(url, headers: headers);
    }
  }

  Future<void> _loadAsset(String uri, {Map<String, String>? headers}) async {
    return this.loadUrl('http://localhost:$_port/$uri', headers: headers);
  }
}

class _Server {
  static HttpServer? _server;

  ///Closes the server.
  static Future<void> close() async {
    if (_server != null) {
      await _server!.close(force: true);
      //  print('Server running on http://localhost:$_port closed');
      _server = null;
    }
  }

  ///Starts the server
  static Future<int> start() async {
    var completer = Completer<int>();

    runZonedGuarded(() {
      HttpServer.bind('localhost', 0, shared: true).then((server) {
        //print('Server running on http://localhost:' + 5353.toString());
        _server = server;
        server.listen((HttpRequest httpRequest) async {
          List<int> body = [];
          String path = httpRequest.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';
          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
          } catch (e) {
            print('Error: $e');
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
    }, (e, stackTrace) => print('Error: $e $stackTrace'));
    return completer.future;
  }
}

class _WebViewPlusState extends State<WebViewPlus> {
  Completer<int> _portCompleter = Completer<int>();

  _WebViewPlusState() {
    _Server.start().then((_port) => _portCompleter.complete(_port));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _portCompleter.future,
      builder: (BuildContext context, AsyncSnapshot<int> snap) {
        if (snap.hasData && !snap.hasError) {
          return WebView(
            allowsInlineMediaPlayback: widget.allowsInlineMediaPlayback,
            onProgress: widget.onProgress,
            key: widget.key,
            onPageStarted: widget.onPageStarted,
            onPageFinished: widget.onPageFinished,
            javascriptMode: widget.javascriptMode,
            javascriptChannels: widget.javascriptChannels,
            onWebViewCreated: (controller) => widget.onWebViewCreated
                ?.call(WebViewPlusController._(controller, snap.data)),
            debuggingEnabled: widget.debuggingEnabled,
            gestureNavigationEnabled: widget.gestureNavigationEnabled,
            gestureRecognizers: widget.gestureRecognizers,
            initialMediaPlaybackPolicy: widget.initialMediaPlaybackPolicy,
            initialUrl: _getInitialUrl(widget.initialUrl, snap.data),
            navigationDelegate: widget.navigationDelegate,
            onWebResourceError: widget.onWebResourceError,
            userAgent: widget.userAgent,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  @override
  void dispose() {
    _Server.close();
    super.dispose();
  }

  String? _getInitialUrl(String? url, int? port) {
    if (url != null) {
      if (Uri.parse(url).isAbsolute) {
        return url;
      } else {
        return 'http://localhost:$port/$url';
      }
    } else
      return null;
  }
}
