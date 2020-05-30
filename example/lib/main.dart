import 'package:flutter/material.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

void main() {
  runApp(InAppWebAppExample());
}

class InAppWebAppExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InAppWebAppMainPage(),
    );
  }
}

class InAppWebAppMainPage extends StatefulWidget {
  @override
  _InAppWebAppMainPageState createState() => _InAppWebAppMainPageState();
}

class _InAppWebAppMainPageState extends State<InAppWebAppMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InAppWebApp Example'),
      ),
      body: WebViewPlus(
        onWebViewCreated: (controller) {
          controller.loadAsset('assets/index.html');
        },
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
