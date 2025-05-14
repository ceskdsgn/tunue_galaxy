// Solo per web
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// Solo per mobile
import 'package:webview_flutter/webview_flutter.dart';

class ARViewerPage extends StatefulWidget {
  const ARViewerPage({Key? key}) : super(key: key);

  @override
  State<ARViewerPage> createState() => _ARViewerPageState();
}

class _ARViewerPageState extends State<ARViewerPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse('ar.html'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Realtà Aumentata')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              html.window.open('ar.html', '_blank');
            },
            child: const Text('Apri AR'),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Realtà Aumentata')),
        body: WebViewWidget(controller: controller),
      );
    }
  }
}
