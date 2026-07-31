import 'package:flutter/material.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/screens/notification_screen.dart';

class NotificationBell extends StatefulWidget {
  final UserModel user;
  final String companyId;
  NotificationBell({super.key, required this.user, required this.companyId});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late bool _isPushOn;
  void initState() {
    super.initState();
    _isPushOn = widget.user.isPushOn;
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 짧게 누르기: 알림 On/Off 토글
      onTap: () async {
        setState(() {
          _isPushOn = !_isPushOn;
          widget.user.isPushOn = _isPushOn;
        });
      },
      //  길게 누르기: 히스토리 화면으로 이동
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NotificationHistoryScreen(companyId: widget.companyId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Icon(
          _isPushOn ? Icons.notifications_active : Icons.notifications_off,
          color: _isPushOn ? Colors.black : Colors.grey, // 켜지면 검은색, 꺼지면 회색
        ),
      ),
    );
  }
}
