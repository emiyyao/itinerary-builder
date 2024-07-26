import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bool App',
      home: BoolScreen(),
    );
  }
}

class BoolScreen extends StatefulWidget {
  @override
  _BoolScreenState createState() => _BoolScreenState();
}

class _BoolScreenState extends State<BoolScreen> {
  bool _asd = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bool App'),
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _asd = true;
                });
              },
              child: Text('Click Me'),
            ),
            if (_asd)
              Text(
                'I\'m here',
                style: TextStyle(fontSize: 24),
              ),
          ],
        ),
      ),
    );
  }
}