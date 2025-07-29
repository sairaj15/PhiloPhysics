// vlab_webview_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VLabWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const VLabWebViewPage({required this.title, required this.url, Key? key})
      : super(key: key);

  @override
  State<VLabWebViewPage> createState() => _VLabWebViewPageState();
}

class _VLabWebViewPageState extends State<VLabWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
