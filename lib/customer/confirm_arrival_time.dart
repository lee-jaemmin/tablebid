import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tablebid/customer/customer_home_screen.dart';
import 'package:tablebid/services/reservation_api.dart';

class ConfirmArrivalTime extends StatefulWidget {
  final int reservationId;

  const ConfirmArrivalTime({super.key, required this.reservationId});

  @override
  State<ConfirmArrivalTime> createState() => _ConfirmArrivalTimeState();
}

class _ConfirmArrivalTimeState extends State<ConfirmArrivalTime> {
  int? _selectedMinutes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAnimation();
      }
    });
    // 이거 없으면 initState끝나기전에 함수 실행
    // => context찾고 이래서 전체 흐름이 중단됨.
  }

  Future<void> _showAnimation() async {
      await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (lottieContext) {
        return Center(
          child: Lottie.asset(
            'assets/lottie/sold.json',
            repeat: false,
            // lottieObject: 로티 파일즈 객체
            // 이게 로딩 되면 onLoaded실행
            // duration: 애니메이션 길이
            // 만큼 기다렸다가 콜백 (pop) 실행
            onLoaded: (lottieObject) {
              Future.delayed(lottieObject.duration, () {
                if (lottieContext.mounted) {
                  Navigator.pop(lottieContext);
                }
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmArrivalTime() async {
    final selectedMinutes = _selectedMinutes;
    if (selectedMinutes == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ReservationApi().updateReservation(
        reservationId: widget.reservationId,
        arrivalAt: DateTime.now().add(Duration(minutes: selectedMinutes)),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('도착 예정 시간을 저장하지 못했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도착 예정 시간 선택')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('5분 내로 도착 시간 응답을 안 하거나 응답한 시간 내에 도착하지 못할 시 매장의 사정에 따라 예약이 취소될 수 있음을 알려드립니다.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildArrivalButton(5, '5분 내 도착')),
                const SizedBox(width: 12),
                Expanded(child: _buildArrivalButton(10, '10분 내 도착')),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: _selectedMinutes == null || _isSubmitting
                  ? null
                  : _confirmArrivalTime,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalButton(int minutes, String label) {
    final isSelected = _selectedMinutes == minutes;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Colors.transparent,
        foregroundColor: isSelected ? Colors.black : Colors.white,
        side: const BorderSide(color: Colors.white),
      ),
      onPressed: _isSubmitting
          ? null
          : () => setState(() => _selectedMinutes = minutes),
      child: Text(label),
    );
  }
}
