import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_plus/src/webview_flutter_plus_server.dart';

typedef void WebViewPlusCreatedCallback(WebViewPlusController controller);

class CodeInjection {
  /// Targeted Code in index.html
  final String from;

  /// Code to replace with.
  final String to;

  CodeInjection({@required this.from, @required this.to});
}

class WebViewPlus extends StatefulWidget {
  /// If not null invoked once the web view is created.
  final WebViewPlusCreatedCallback onWebViewCreated;

  /// Which gestures should be consumed by the web view.
  ///
  /// It is possible for other gesture recognizers to be competing with the web view on pointer
  /// events, e.g if the web view is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The web view will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// When this set is empty or null, the web view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The initial URL to load.
  final String initialUrl;

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
  final Set<JavascriptChannel> javascriptChannels;

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
  final NavigationDelegate navigationDelegate;

  /// Invoked when a page starts loading.
  final PageStartedCallback onPageStarted;

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
  final PageFinishedCallback onPageFinished;

  /// Invoked when a web resource has failed to load.
  ///
  /// This can be called for any resource (iframe, image, etc.), not just for
  /// the main page.
  final WebResourceErrorCallback onWebResourceError;

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
  final String userAgent;

  /// Which restrictions apply on automatic media playback.
  ///
  /// This initial value is applied to the platform's webview upon creation. Any following
  /// changes to this parameter are ignored (as long as the state of the [WebView] is preserved).
  ///
  /// The default policy is [AutoMediaPlaybackPolicy.require_user_action_for_all_media_types].
  final AutoMediaPlaybackPolicy initialMediaPlaybackPolicy;

  /// Callback for [HttpRequest] from client side.
  final void Function(HttpRequest httpRequest) onRequest;

  /// This helps to replace code in loaded index.html at a particular position.
  final CodeInjection Function() codeInjection;

  /// Creates a new web view.
  ///
  /// The web view can be controlled using a `WebViewController` that is passed to the
  /// `onWebViewCreated` callback once the web view is created.
  ///
  /// The `javascriptMode` and `autoMediaPlaybackPolicy` parameters must not be null.
  const WebViewPlus(
      {Key key,
      this.onWebViewCreated,
      this.initialUrl,
      this.javascriptMode = JavascriptMode.disabled,
      this.javascriptChannels,
      this.navigationDelegate,
      this.gestureRecognizers,
      this.onPageStarted,
      this.onPageFinished,
      this.onWebResourceError,
      this.debuggingEnabled = false,
      this.gestureNavigationEnabled = false,
      this.userAgent,
      this.initialMediaPlaybackPolicy =
          AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
      this.onRequest,
      this.codeInjection})
      : assert(javascriptMode != null),
        assert(initialMediaPlaybackPolicy != null),
        super(key: key);

  @override
  _WebViewPlusState createState() => _WebViewPlusState();
}

class WebViewPlusController implements WebViewController {
  final WebViewController _webViewController;

  final int _serverPort;

  WebViewPlusController._(this._webViewController, this._serverPort);

  @override
  Future<bool> canGoBack() {
    return _webViewController.canGoBack();
  }

  @override
  Future<bool> canGoForward() {
    return _webViewController.canGoForward();
  }

  @override
  Future<void> clearCache() {
    return _webViewController.clearCache();
  }

  @override
  Future<String> currentUrl() {
    return _webViewController.currentUrl();
  }

  @override
  Future<String> evaluateJavascript(String javascriptString) {
    return _webViewController.evaluateJavascript(javascriptString);
  }

  @override
  Future<int> getScrollX() {
    return _webViewController.getScrollX();
  }

  @override
  Future<int> getScrollY() {
    return _webViewController.getScrollY();
  }

  int getServerPort() {
    return _serverPort;
  }

  @override
  Future<String> getTitle() {
    return _webViewController.getTitle();
  }

  Future<double> getWebviewPlusHeight() async {
    String getHeightScript = r"""
    getWebviewFlutterPlusHeight();
    function getWebviewFlutterPlusHeight(){
    var element = document.body;
    var height = element.offsetHeight,
        style = window.getComputedStyle(element)
    return ['top', 'bottom']
        .map(function (side) {
            return parseInt(style["margin-" + side]);
        })
        .reduce(function (total, side) {
            return total + side;
        }, height)}""";
    return double.parse(await evaluateJavascript(getHeightScript));
  }

  @override
  Future<void> goBack() {
    return _webViewController.goBack();
  }

  @override
  Future<void> goForward() {
    return _webViewController.goForward();
  }

  Future<void> loadAsset(String uri) {
    return this.loadUrl('http://localhost:$_serverPort/$uri');
  }

  Future<void> loadString(String code) {
    return this
        .loadUrl(Uri.dataFromString(code, mimeType: 'text/html').toString());
  }

  @override
  Future<void> loadUrl(String url, {Map<String, String> headers}) {
    return _webViewController.loadUrl(url, headers: headers);
  }

  @override
  Future<void> reload() {
    return _webViewController.reload();
  }

  @override
  Future<void> scrollBy(int x, int y) {
    return _webViewController.scrollBy(x, y);
  }

  @override
  Future<void> scrollTo(int x, int y) {
    return _webViewController.scrollTo(x, y);
  }
}

class _WebViewPlusState extends State<WebViewPlus> {
  WebViewFlutterPlusServer _server;

  @override
  Widget build(BuildContext context) {
    return WebView(
      key: widget.key,
      onPageStarted: widget.onPageStarted,
      onPageFinished: widget.onPageFinished,
      javascriptMode: widget.javascriptMode,
      javascriptChannels: widget.javascriptChannels,
      onWebViewCreated: (controller) {
        _server = WebViewFlutterPlusServer()
          ..start(widget.onRequest, widget.codeInjection).then((port) {
            widget.onWebViewCreated(WebViewPlusController._(controller, port));
          });
      },
      debuggingEnabled: widget.debuggingEnabled,
      gestureNavigationEnabled: widget.gestureNavigationEnabled,
      gestureRecognizers: widget.gestureRecognizers,
      initialMediaPlaybackPolicy: widget.initialMediaPlaybackPolicy,
      initialUrl: widget.initialUrl,
      navigationDelegate: widget.navigationDelegate,
      onWebResourceError: widget.onWebResourceError,
      userAgent: widget.userAgent,
    );
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }
}
