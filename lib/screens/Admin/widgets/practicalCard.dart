import 'package:ephysicsapp/globals/colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget practicalUserCard({
  required String practicalUrl,
  required String moduleName,
  required BuildContext context,
}) {
  return Container(
    margin: EdgeInsets.fromLTRB(10, 7, 10, 7),
    child: Card(
      elevation: 3,
      color: color1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(100)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(width: 1.0, color: color5)),
          ),
          child: Icon(Icons.science,
              color: color5), // Use a science icon for practicals
        ),
        title: Text(
          "Practical Experiment",
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: color5,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'Interactive experiment for $moduleName',
          style: TextStyle(
            color: Colors.black.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.keyboard_arrow_right, color: color5, size: 30.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PracticalWebViewScreen(
                url: practicalUrl,
                moduleName: moduleName,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class PracticalWebViewScreen extends StatefulWidget {
  final String url;
  final String moduleName;
  const PracticalWebViewScreen({
    Key? key,
    required this.url,
    required this.moduleName,
  }) : super(key: key);

  @override
  State<PracticalWebViewScreen> createState() => _PracticalWebViewScreenState();
}

class _PracticalWebViewScreenState extends State<PracticalWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.moduleName} Practical'),
        ),
        body: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop && await _controller.canGoBack()) {
              _controller.goBack();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
