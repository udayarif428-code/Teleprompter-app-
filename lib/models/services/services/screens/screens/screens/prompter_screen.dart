import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../models/script.dart';
import '../services/stt_matcher_service.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/pace_meter.dart';

class PrompterScreen extends StatefulWidget {
  final ScriptModel script;
  const PrompterScreen({super.key, required this.script});

  @override
  State<PrompterScreen> createState() => _PrompterScreenState();
}

class _PrompterScreenState extends State<PrompterScreen> {
  final SttMatcherService _stt = SttMatcherService();
  final ScrollController _scrollController = ScrollController();

  bool _showCountdown = false;
  bool _isRunning = false;
  String _status = 'paused';
  double _wpm = 0;
  double _fontSize = 28;
  bool _bubbleModeActive = false;

  @override
  void initState() {
    super.initState();
    _stt.loadScript(widget.script.content);
    _stt.onPositionUpdate = _onPositionUpdate;
    _stt.onPaceUpdate = (wpm) => setState(() => _wpm = wpm);
    _stt.onStatusChange = (status) => setState(() => _status = status);
    _stt.init();
  }

  void _onPositionUpdate(int index) {
    setState(() {});
    _autoScroll(index);
    _pushOverlayFrame(index);
  }

  void _autoScroll(int index) {
    if (!_scrollController.hasClients || _stt.scriptWords.isEmpty) return;
    final progress = index / _stt.scriptWords.length;
    final target = progress * _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _pushOverlayFrame(int index) {
    if (!_bubbleModeActive) return;
    final start = (index - 6).clamp(0, _stt.scriptWords.length);
    final end = (index + 20).clamp(0, _stt.scriptWords.length);
    final windowWords = _stt.scriptWords.sublist(start, end);
    final relativeIndex = index - start;
    FlutterOverlayWindow.shareData(jsonEncode({
      'words': windowWords,
      'index': relativeIndex,
      'wpm': _wpm,
      'fontSize': 20.0,
    }));
  }

  Future<void> _startFlow() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showSnack('মাইক্রোফোন পারমিশন দরকার');
      return;
    }
    setState(() => _showCountdown = true);
  }

  Future<void> _onCountdownFinished() async {
    setState(() {
      _showCountdown = false;
      _isRunning = true;
    });
    final localeId = widget.script.language == 'bn' ? 'bn_BD' : 'en_US';
    await _stt.startListening(localeId: localeId);
  }

  Future<void> _stopFlow() async {
    await _stt.stopListening();
    setState(() => _isRunning = false);
  }

  void _panicReset() {
    _stt.resetToStart();
    _scrollController.jumpTo(0);
    _showSnack('শুরুতে ফিরে গেলাম');
  }

  Future<void> _toggleBubbleMode() async {
    if (_bubbleModeActive) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _bubbleModeActive = false);
      return;
    }
    final overlayStatus = await Permission.systemAlertWindow.request();
    if (!overlayStatus.isGranted) {
      _showSnack('"Draw over other apps" পারমিশন দরকার');
      return;
    }
    await FlutterOverlayWindow.showOverlay(
      height: 130,
      width: 260,
      alignment: OverlayAlignment.centerRight,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      enableDrag: true,
    );
    setState(() => _bubbleModeActive = true);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    _stt.dispose();
    if (_bubbleModeActive) FlutterOverlayWindow.closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: RichText(
                      text: TextSpan(
                        children: List.generate(_stt.scriptWords.length, (i) {
                          final isCurrent = i == _stt.currentWordIndex;
                          final isPast = i < _stt.currentWordIndex;
                          return TextSpan(
                            text: '${_stt.scriptWords[i]} ',
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.6,
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
                _buildBottomBar(),
              ],
            ),
          ),
          if (_showCountdown)
            Positioned.fill(child: CountdownOverlay(onFinished: _onCountdownFinished)),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(widget.script.title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
          PaceMeter(wpm: _wpm),
          const SizedBox(width: 6),
          Icon(
            _status.startsWith('listening') ? Icons.mic : Icons.mic_off,
            color: _status.startsWith('listening') ? Colors.greenAccent : Colors.white30,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.text_decrease, color: Colors.white54),
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(16, 60)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, color: Colors.white54),
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(16, 60)),
          ),
          IconButton(
            icon: const Icon(Icons.replay_circle_filled, color: Colors.orangeAccent, size: 30),
            tooltip: 'শুরুতে ফিরে যাও',
            onPressed: _panicReset,
          ),
          GestureDetector(
            onTap: _isRunning ? _stopFlow : _startFlow,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: _isRunning ? Colors.redAccent : Colors.yellowAccent,
              child: Icon(_isRunning ? Icons.stop : Icons.play_arrow, color: Colors.black),
            ),
          ),
          IconButton(
            icon: Icon(Icons.picture_in_picture_alt,
                color: _bubbleModeActive ? Colors.greenAccent : Colors.white54),
            tooltip: 'Bubble মোড (ক্যামেরার পাশে)',
            onPressed: _toggleBubbleMode,
          ),
        ],
      ),
    );
  }
}
