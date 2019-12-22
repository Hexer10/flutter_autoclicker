import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:dart_winapi/user32.dart';
import 'package:flutter/services.dart';

import 'keys.dart';

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
      title: 'Flutter AutoClicker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter AutoClicker'),
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
  var _key = 'ALT';
  var _clickCount = 0;
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
            Text('Press ${_key ?? 'INVALID'} to toggle'),
            Container(
              alignment: Alignment.center,
              width: 400,
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                readOnly: _start,
                initialValue: '100',
                onChanged: (string) {
                  var n = int.tryParse(string.trim());
                  if (n == null || 0 >= n) {
                    _cps = null;
                    return;
                  }
                  _cps = n;
                },
                decoration: InputDecoration(labelText: 'Click speed in ms'),
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: 400,
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                readOnly: _start,
                initialValue: '0',
                onChanged: (string) {
                  var n = int.tryParse(string.trim());
                  if (n == null || 0 >= n) {
                    _clickCount = null;
                    return;
                  }
                  _clickCount = n;
                },
                decoration: InputDecoration(
                    labelText: 'Click count (0 = until stopped)'),
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: 400,
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                maxLength: 5,
                readOnly: _start,
                initialValue: 'ALT',
                onChanged: (string) {
                  var valid = keys[string.toUpperCase()] != null;
                  print('Changed: $valid');
                  if (valid) {
                    setState(() {
                      _key = string.toUpperCase();
                    });
                  } else {
                    setState(() {
                      _key = null;
                      _start = false;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Toggle Key'),
              ),
            ),
            RaisedButton(
              child: _leftClick ? Text('Left Click') : Text('Right Click'),
              onPressed: () {
                if (_start) {
                  return;
                }
                setState(() {
                  _leftClick = !_leftClick;
                });
              },
            ),
            RaisedButton(
              child: _start ? Text('Started') : Text('Stopped'),
              onPressed: () async {
                if (_cps == null || _key == null) {
                  return;
                }
                print('Cps: $_cps');
                setState(() {
                  _start = !_start;
                });
                if (_start) {
                  print('Waiting keypress...');
                  Future.doWhile(() async {
                    if (!_start) {
                      return false;
                    }
                    var key = keys[_key];
                    if (key == null) {
                      // Avoid too many calls.
                      await Future.delayed(Duration(milliseconds: 100));
                      return true;
                    }
                    await keyPress(key);
                    var count = 0;
                    _timer2 =
                        Timer.periodic(Duration(milliseconds: _cps), (timer) {
                      if (_clickCount != 0) {
                        count++;
                      }
                      if (_leftClick) {
                        MouseEvent(dwFlags: MOUSEEVENTF_LEFTDOWN);
                        MouseEvent(dwFlags: MOUSEEVENTF_LEFTUP);
                      } else {
                        MouseEvent(dwFlags: MOUSEEVENTF_RIGHTDOWN);
                        MouseEvent(dwFlags: MOUSEEVENTF_RIGHTUP);
                      }
                      if (_clickCount != 0 && count == _clickCount) {
                        _timer.cancel();
                        timer.cancel();
                        setState(() {
                          _start = false;
                        });
                      }
                    });
                    if (!_start) {
                      return false;
                    }
                    await keyPress(key);
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
