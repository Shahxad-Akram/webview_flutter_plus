# webview_flutter_plus

# Contents
* [About](#about)
* [How to use?](#how-to-use)
   * [Android](#android)
   * [iOS](#ios)
* [Examples](#examples)
    * [Loading From String](#loading-from-string)
    * [Loading From Asset](#loading-from-assets)
    * [Use in ListView](#use-in-listview)
* [API differences from webview_flutter](#api-differences-from-webview_flutter)

# About
webview_flutter_plus is a powerful extension of [webview_flutter](https://pub.dartlang.org/packages/webview_flutter). This package helps to load Local HTML, CSS and Javascript content from Assets or Strings. This inherits all features of webview_flutter with minor API changes.

Do check [**flutter_tex**](https://pub.dartlang.org/packages/flutter_tex) a powerful implementation of this package.


# What's unique in webview_flutter_plus
* Load HTML, CSS and Javascript content from Assets, [see example](#loading-from-assets).
* Load HTML, CSS and Javascript content from Strings, [see example](#loading-from-string).
* Get height of Web content which will allow you to use `WebviewPlus` widget even in list view, [see example](#use-in-listview).
* It includes all features of its parent plugin [webview_flutter](https://pub.dartlang.org/packages/webview_flutter).

# How to use?
**1:** Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  webview_flutter_plus: ^0.3.0
```

**2:** You can install packages from the command line:

```bash
$ flutter packages get
```

Alternatively, your editor might support flutter packages get. Check the docs for your editor to learn more.


**3:** Now you need to put the following implementations in `Android` and `iOS` respectively.

### Android
Make sure to add this line `android:usesCleartextTraffic="true"` in your `<project-directory>/android/app/src/main/AndroidManifest.xml` under `application` like this.
```xml
<application
       android:usesCleartextTraffic="true">
</application>
```

Required Permissions are:
```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS
Add following code in your `<project-directory>/ios/Runner/Info.plist`
```plist
<key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key> <true/>
  </dict>
<key>io.flutter.embedded_views_preview</key> <true/> 
```

**4:** Now in your Dart code, you can use:

```dart
import 'package:webview_flutter_plus/webview_flutter_plus.dart'; 
```

**5:** Now you can use WebViewPlus as a widget:

# Examples

#### Loading From String
```dart
WebViewPlus(
    javascriptMode: JavascriptMode.unrestricted,
    onWebViewCreated: (controller) {
      controller.loadString(r"""
           <html lang="en">
            <body>hello world</body>
           </html>
      """);
    },
  )
```

#### Loading from Assets
It is mandatory to mention all associated HTML, CSS and Javascript files in `pubspecs.yaml` under `assets:`
```dart
WebViewPlus(
    javascriptMode: JavascriptMode.unrestricted,
    onWebViewCreated: (controller) {
      controller.loadUrl('assets/index.html');
    },
  )
```

#### Use in ListView
`WebViewPlusController` also allows you to get `WebViewPlus` height like `controller.getHeight()`

```dart
WebViewPlusController _controller;
double _height = 1;

@override
Widget build(BuildContext context) {
return Scaffold(
  appBar: AppBar(
    title: Text('ListView Example'),
  ),
  body: ListView(
    children: [
      SizedBox(
        height: _height,
        child: WebViewPlus(
          onWebViewCreated: (controller) {
            this._controller = controller;
            controller.loadUrl('assets/index.html');
          },
          onPageFinished: (url) {
            _controller.getHeight().then((double height) {
              print("Height:  " + height.toString());
              setState(() {
                _height = height;
              });
            });
          },
          javascriptMode: JavascriptMode.unrestricted,
        ),
      )
    ],
  ),
);
}
```

# Plus APIs
`WebViewPlusController controller;`

* `controller.loadUrl('path/to/index.html')` load HTML content from Assets.
* `controller.loadString(r"<html>HTML, CSS and Javascript code in raw string</html>");` load HTML, CSS and Javascript Code from a String.
* `controller.getHeight()` returns height of WebViewPlus.

# API differences from webview_flutter
There are very minor API differences as following.

webview_flutter          |webview_flutter_plus
:-----------------------:|:---------------------------:
`WebView`                |`WebViewPlus`
`WebViewController`      |`WebViewPlusController` contains `WebViewController` inside.
`WebViewCreatedCallback` |`WebViewPlusCreatedCallback`

Rest everything is same as webview_flutter.