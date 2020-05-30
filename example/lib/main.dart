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
  WebViewPlusController _controller;
  double _height = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('InAppWebApp Example'),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: _height,
            child: WebViewPlus(
              onWebViewCreated: (controller) {
                this._controller = controller;
                controller.loadAsset('assets/index.html');
              },
              onPageFinished: (url) {
                _controller.getWebviewPlusHeight().then((double height) {
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
}
