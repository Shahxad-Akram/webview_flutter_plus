import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

void main() {
  runApp(const WebViewPlusExample());
}

class WebViewPlusExample extends StatelessWidget {
  const WebViewPlusExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late WebViewPlusController _controler;

  double _height = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('webview_flutter_plus Example'),
        ),
        body: ListView(
          children: [
            Text("Height of WebviewPlus: $_height",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: _height,
              child: WebviewPlusBuilder(
                (controler) {
                  if (kDebugMode) {
                    print("Server port: ${controler.port}");
                  }
                  _controler = controler
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..setBackgroundColor(const Color(0x00000000))
                    ..setNavigationDelegate(
                      NavigationDelegate(
                        onPageFinished: (String url) {
                          // Get height of WebviewPlus
                          _controler.getWebViewHeight().then((value) {
                            var height = int.parse(value.toString()).toDouble();
                            if (height != _height) {
                              if (kDebugMode) {
                                print("Height is: $value");
                              }
                              setState(() {
                                _height = height;
                              });
                            }
                          });
                        },
                      ),
                    )
                    ..loadAssetOnServer('assets/index.html');
                  return WebViewWidget(
                    controller: controler,
                  );
                },
              ),
            ),
            const Text("End of WebviewPlus",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ));
  }
}
