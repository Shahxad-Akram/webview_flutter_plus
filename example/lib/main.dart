import 'package:flutter/material.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

void main() {
  runApp(WebViewPlusExample());
}

class WebViewPlusExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebViewPlusExampleMainPage(),
    );
  }
}

class WebViewPlusExampleMainPage extends StatefulWidget {
  @override
  _WebViewPlusExampleMainPageState createState() =>
      _WebViewPlusExampleMainPageState();
}

class _WebViewPlusExampleMainPageState
    extends State<WebViewPlusExampleMainPage> {
  WebViewPlusController _controller;
  double _height = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('webview_flutter_plus Example'),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 500,
            child: WebViewPlus(
              initialUrl: 'assets/index.html',
              onWebViewCreated: (controller) {
                this._controller = controller;
              },
              onPageFinished: (url) {
                _controller.getHeight().then((double height) {
                  print("Height: " + height.toString());
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
}
