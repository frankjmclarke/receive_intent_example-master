import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription? _dataStreamSubscription;
  var loadingPercentage = 0;
  late final WebViewController controller;
  String _sharedText = 'https://flutter.dev';

  List<SharedMediaFile>? _sharedFiles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* appBar: AppBar(
        centerTitle: true,
        title: const Text("Receive intent example"),
      ),*/
      body: Container(
        //margin: const EdgeInsets.only(top: 10, left: 10, right: 10),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.yellow,
                child: WebViewWidget(
                  controller: controller,
                ),
              ),
            ),
            const Text(
              "Shared Text is :",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(_sharedText, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            const Text("Shared files:",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(
              width: 5,
            ),
            if (_sharedFiles != null)
              Text(_sharedFiles!.map((f) => f.path).join(",") ?? "",
                  style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            loadingPercentage = 0;
          });
        },
        onProgress: (progress) {
          setState(() {
            loadingPercentage = progress;
          });
        },
        onPageFinished: (url) {
          setState(() {
            loadingPercentage = 100;
          });
        },
      ))
      ..loadRequest(
        //Uri.parse('https://flutter.dev'),
        Uri.parse(_sharedText),
      );

    //Receive text data when app is running
    _dataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String text)  async {
      setState(()  {
        _sharedText = text;


      });
      await controller.loadRequest(Uri.parse(text));
       //controller.loadRequest(Uri.parse('https://youtube.com'));
    });

    //Receive text data when app is closed
    ReceiveSharingIntent.getInitialText().then((String? text) async {
      if (text != null) {
        setState(() {
          _sharedText = text;
        });

        controller.loadRequest(Uri.parse(_sharedText));
        controller.reload();
      }
    });

    //Receive files when app is running
    _dataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> files) {
      setState(() {
        _sharedFiles = files;
      });
    });

    //Receive files when app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> files) {
      if (files != null) {
        setState(() {
          _sharedFiles = files;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _dataStreamSubscription!.cancel();
  }
}
