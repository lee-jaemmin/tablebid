import 'package:flutter/material.dart';

// 자식 클래스로 변경
class TimerBadge extends StatelessWidget {
  final String timerDisplay; // "00:00" 같은 시간 글씨
  final bool isExpired; // 만료 여부

  const TimerBadge({
    super.key,
    required this.timerDisplay,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: isExpired ? Colors.red : Colors.pink[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 14, color: Colors.white),
            const SizedBox(width: 2),
            Text(
              timerDisplay,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}