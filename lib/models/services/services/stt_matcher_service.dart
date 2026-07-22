import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// This is the "brain" of the teleprompter.
/// It listens continuously, breaks your script into words,
/// and figures out WHERE in the script you currently are —
/// even if you skip words, repeat, or the recognizer mishears something.
class SttMatcherService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool isListening = false;
  bool isAvailable = false;

  // The full script, split into normalized word tokens.
  List<String> scriptWords = [];

  // Current "cursor" position inside scriptWords.
  int currentWordIndex = 0;

  // Words-per-minute pace tracking.
  final List<DateTime> _recentWordTimestamps = [];

  // Callbacks the UI listens to.
  void Function(int wordIndex)? onPositionUpdate;
  void Function(double wpm)? onPaceUpdate;
  void Function(String status)? onStatusChange; // 'listening' | 'paused' | 'error'

  Timer? _silenceTimer;
  static const _silenceTimeout = Duration(seconds: 2);

  Future<bool> init() async {
    isAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          onStatusChange?.call('paused');
        }
      },
      onError: (error) => onStatusChange?.call('error: ${error.errorMsg}'),
    );
    return isAvailable;
  }

  /// localeId examples: 'bn_BD' (Bengali), 'en_US' (English)
  void loadScript(String fullText) {
    scriptWords = _normalize(fullText)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    currentWordIndex = 0;
  }

  Future<void> startListening({required String localeId}) async {
    if (!isAvailable) return;
    isListening = true;
    onStatusChange?.call('listening');
    await _speech.listen(
      localeId: localeId,
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (result) => _handleRecognized(result.recognizedWords),
      pauseFor: const Duration(seconds: 5),
      listenFor: const Duration(minutes: 30),
    );
  }

  Future<void> stopListening() async {
    isListening = false;
    await _speech.stop();
    onStatusChange?.call('paused');
  }

  void resetToStart() {
    currentWordIndex = 0;
    onPositionUpdate?.call(0);
  }

  void _handleRecognized(String heardText) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, () {
      // No new speech for 2s -> treat as paused. Scrolling should freeze
      // because we simply stop calling onPositionUpdate.
      onStatusChange?.call('paused');
    });

    final heardWords = _normalize(heardText).split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty).toList();
    if (heardWords.isEmpty) return;

    onStatusChange?.call('listening');
    _trackPace(heardWords.length);

    // Look at the last 2-4 heard words and find the best matching
    // location in a forward-looking window of the script (never search
    // backwards far — people rarely jump back).
    final tailCount = heardWords.length >= 4 ? 4 : heardWords.length;
    final tail = heardWords.sublist(heardWords.length - tailCount);

    final bestIndex = _findBestAlignment(tail);
    if (bestIndex != null && bestIndex >= currentWordIndex) {
      currentWordIndex = bestIndex;
      onPositionUpdate?.call(currentWordIndex);
    }
  }

  /// Fuzzy sliding-window search: look ahead up to 40 words from current
  /// position, and find the window that best matches the recently heard
  /// words using normalized edit-distance similarity.
  int? _findBestAlignment(List<String> heardTail) {
    const lookahead = 40;
    final searchEnd = (currentWordIndex + lookahead < scriptWords.length)
        ? currentWordIndex + lookahead
        : scriptWords.length;

    double bestScore = 0.0;
    int? bestEndIndex;

    for (int start = currentWordIndex;
        start < searchEnd - heardTail.length + 1 && start < scriptWords.length;
        start++) {
      final end = (start + heardTail.length <= scriptWords.length)
          ? start + heardTail.length
          : scriptWords.length;
      final window = scriptWords.sublist(start, end);
      final score = _windowSimilarity(heardTail, window);
      if (score > bestScore) {
        bestScore = score;
        bestEndIndex = end;
      }
    }

    // Only accept a match if it's reasonably confident (tolerant threshold
    // because Bengali/English STT output is noisy).
    if (bestScore >= 0.35) return bestEndIndex;
    return null;
  }

  double _windowSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    int matches = 0;
    final len = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < len; i++) {
      if (_similarWord(a[i], b[i])) matches++;
    }
    return matches / a.length;
  }

  bool _similarWord(String a, String b) {
    if (a == b) return true;
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return false;
    // Allow ~40% character-level difference (handles STT mis-hearing).
    return (1 - dist / maxLen) >= 0.6;
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    List<int> prev = List.generate(s2.length + 1, (i) => i);
    List<int> curr = List.filled(s2.length + 1, 0);
    for (int i = 1; i <= s1.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      prev = List.from(curr);
    }
    return prev[s2.length];
  }

  void _trackPace(int newWordCount) {
    final now = DateTime.now();
    for (int i = 0; i < newWordCount; i++) {
      _recentWordTimestamps.add(now);
    }
    // Keep only last 15 seconds of words for a rolling WPM estimate.
    _recentWordTimestamps.removeWhere(
        (t) => now.difference(t) > const Duration(seconds: 15));
    final wpm = _recentWordTimestamps.length * (60 / 15);
    onPaceUpdate?.call(wpm);
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]', unicode: true), ' ')
        .trim();
  }

  void dispose() {
    _silenceTimer?.cancel();
    _speech.stop();
  }
}
