import 'package:ephysicsapp/globals/constants.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:no_screenshot/no_screenshot.dart'; // Add this import

class VlabsScreen extends StatefulWidget {
  @override
  State<VlabsScreen> createState() => _VlabsScreenState();
}

class _VlabsScreenState extends State<VlabsScreen> {
  late final WebViewController _controller;
  final NoScreenshot _noScreenshot = NoScreenshot(); // Create instance

  @override
  void initState() {
    super.initState();
    print("V-Labs Screen Called");

    _noScreenshot.screenshotOff();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(Uri.parse(vlabsWebUrl));
  }

  @override
  void dispose() {
    _noScreenshot.screenshotOn();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Sakec V-Labs',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 2,
        ),
        body: WillPopScope(
          onWillPop: () async {
            if (await _controller.canGoBack()) {
              _controller.goBack();
              return false;
            }
            return true;
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: WebViewWidget(controller: _controller),
          ),
        ),
      ),
    );
  }
}
