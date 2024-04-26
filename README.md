# webview_flutter_plus

# Contents
- [webview\_flutter\_plus](#webview_flutter_plus)
- [Contents](#contents)
- [About](#about)
- [Features](#features)
- [How to use?](#how-to-use)
    - [Android](#android)
    - [iOS](#ios)
- [Example](#example)
    - [Please check `example/lib/main.dart`](#please-check-examplelibmaindart)

# About
webview_flutter_plus is a powerful extension of [webview_flutter](https://pub.dartlang.org/packages/webview_flutter). This package helps to load Local HTML, CSS and Javascript content from Assets or Strings via a local server. This inherits all features of webview_flutter with minor API changes in `WebViewController`.

Do check [**flutter_tex**](https://pub.dartlang.org/packages/flutter_tex) an implementation of this package.

# Features
- Load Local `HTML`, `CSS` and `Javascript` (and all kind of web) content from Assets via a local server.
- Get `WebViewWidget` height to render in a `ListView`.
- `onLoaded` event from Javascript `window.onload`.

# How to use?
**1:** Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  webview_flutter_plus: ^0.4.5
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

# Example

### Please check [`example/lib/main.dart`](https://github.com/shah-xad/webview_flutter_plus/blob/master/example/lib/main.dart)