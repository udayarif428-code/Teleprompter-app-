import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'pace_meter.dart';

/// This runs in a SEPARATE isolate as the floating "bubble" window.
/// It receives data pushed from the main app (current script text,
/// current word index, pace) via FlutterOverlayWindow's shared stream.
class OverlayPrompterWidget extends StatefulWidget {
  const OverlayPrompterWidget({super.key});

  @override
  State<OverlayPrompterWidget> createState() => _OverlayPrompterWidgetState();
}

class _OverlayPrompterWidgetState extends State<OverlayPrompterWidget> {
  List<String> _words = [];
  int _currentIndex = 0;
  double _wpm = 0;
  double _fontSize = 22;
  double _opacity = 0.85;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      try {
        final data = jsonDecode(event as String);
        setState(() {
          if (data['words'] != null) {
            _words = List<String>.from(data['words']);
          }
          _currentIndex = data['index'] ?? _currentIndex;
          _wpm = (data['wpm'] ?? 0).toDouble();
          _fontSize = (data['fontSize'] ?? _fontSize).toDouble();
        });
        _scrollToCurrent();
      } catch (_) {
        // Ignore malformed frames
      }
    });
  }

  void _scrollToCurrent() {
    // Rough auto-scroll: keep the current word roughly a third of the way down.
    if (!_scrollController.hasClients) return;
    final target = (_currentIndex * (_fontSize + 6)) - 40;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap the bubble to close it and return focus to the main app.
        FlutterOverlayWindow.closeOverlay();
      },
      child: Opacity(
        opacity: _opacity,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.drag_indicator, color: Colors.white38, size: 14),
                  PaceMeter(wpm: _wpm, compact: true),
                ],
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 60,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: RichText(
                    text: TextSpan(
                      children: List.generate(_words.length, (i) {
                        final isCurrent = i == _currentIndex;
                        final isPast = i < _currentIndex;
                        return TextSpan(
                          text: '${_words[i]} ',
                          style: TextStyle(
                            fontSize: _fontSize,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent
                                ? Colors.yellowAccent
                                : isPast
                                    ? Colors.white30
                                    : Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
