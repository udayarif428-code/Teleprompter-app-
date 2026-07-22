import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/overlay_widget.dart';

void main() {
  runApp(const TeleprompterApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(
      color: Colors.transparent,
      child: OverlayPrompterWidget(),
    ),
  ));
}

class TeleprompterApp extends StatelessWidget {
  const TeleprompterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Teleprompter',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Colors.yellowAccent),
      ),
      home: const HomeScreen(),
    );
  }
}
