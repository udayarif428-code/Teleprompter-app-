import 'package:flutter/material.dart';

/// Shows whether the user is speaking too slow, normal, or too fast.
/// Normal conversational speaking pace ~110-160 WPM.
class PaceMeter extends StatelessWidget {
  final double wpm;
  final bool compact;

  const PaceMeter({super.key, required this.wpm, this.compact = false});

  Color _color() {
    if (wpm < 90) return Colors.blueAccent; // too slow
    if (wpm > 180) return Colors.redAccent; // too fast
    return Colors.greenAccent; // just right
  }

  String _label() {
    if (wpm < 90) return 'Slow down a bit';
    if (wpm > 180) return 'Slow down!';
    return 'Good pace';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10, vertical: compact ? 2 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: compact ? 12 : 16, color: color),
          const SizedBox(width: 4),
          Text(
            compact ? '${wpm.round()}' : '${wpm.round()} wpm · ${_label()}',
            style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
