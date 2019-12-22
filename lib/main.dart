import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:dart_winapi/user32.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _leftClick = true;
  var _start = false;
  var _cps = 100;
  Timer _timer;
  Timer _timer2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_start) Text('Press ALT to toggle'),
            Container(
              alignment: Alignment.center,
              width: 400,
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (string) {
                  if (string.trim().isEmpty) {
                    return;
                  }
                  _cps = int.tryParse(string.trim());
                },
                decoration: InputDecoration(labelText: 'Click speed in ms'),
              ),
            ),
            RaisedButton(
              child: _leftClick ? Text('Left Click') : Text('Right Click'),
              onPressed: () {
                setState(() {
                  _leftClick = !_leftClick;
                });
              },
            ),
            RaisedButton(
              child: _start ? Text('Started') : Text('Stopped'),
              onPressed: () async {
                setState(() {
                  _start = !_start;
                });
                if (_start) {
                  print('Waiting keypress...');
                  Future.doWhile(() async {
                    if (!_start) {
                      return false;
                    }
                    await keyPress(0x12);
                    _timer2 = Timer.periodic(Duration(milliseconds: _cps), (_) {
                      if (_leftClick) {
                        MouseEvent(dwFlags: MOUSEEVENTF_LEFTDOWN);
                        MouseEvent(dwFlags: MOUSEEVENTF_LEFTUP);
                      } else {
                        MouseEvent(dwFlags: MOUSEEVENTF_RIGHTDOWN);
                        MouseEvent(dwFlags: MOUSEEVENTF_RIGHTUP);
                      }
                    });
                    if (!_start) {
                      return false;
                    }
                    await keyPress(0x12);
                    _timer2?.cancel();
                    return true;
                  });
                } else {
                  print('Stop Waiting');
                  _timer?.cancel();
                  _timer2?.cancel();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Completes when the key is pressed and released.
  Future<void> keyPress(int key) async {
    var completer = Completer<void>();
    bool pressing = false;
    _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      var x = GetKeyState(key) & 0x8000;
      if (x == 0) {
        if (pressing) {
          timer.cancel();
          completer.complete();
          return;
        }
        return;
      }
      pressing = true;
      return;
    });
    return completer.future;
  }
}
