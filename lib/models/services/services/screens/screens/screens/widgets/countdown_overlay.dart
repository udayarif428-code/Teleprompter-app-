import 'dart:async';
import 'package:flutter/material.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  const CountdownOverlay({super.key, required this.onFinished});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _count--);
      if (_count <= 0) {
        t.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Text(
        _count > 0 ? '$_count' : 'Go!',
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 96,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
