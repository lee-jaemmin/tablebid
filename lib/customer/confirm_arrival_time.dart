import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:tablebid/customer/customer_home_screen.dart';
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class ConfirmArrivalTime extends StatefulWidget {
  final int reservationId;

  const ConfirmArrivalTime({super.key, required this.reservationId});

  @override
  State<ConfirmArrivalTime> createState() => _ConfirmArrivalTimeState();
}

class _ConfirmArrivalTimeState extends State<ConfirmArrivalTime> {
  int? _selectedMinutes;
  bool _isSubmitting = false;
  ReservationModel? _reservation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getReservation();

      if (mounted && _reservation != null) {
        await _showAnimation();
      }
    });
  }

  Future<void> _getReservation() async {
    try {
      final r = await ReservationApi().getReservation(widget.reservationId);
      setState(() {
        _reservation = r;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _showAnimation() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (lottieContext) {
        return Material(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/sold.json',
                repeat: false,
                // lottieObject: 로티 파일즈 객체
                // 이게 로딩 되면 onLoaded실행
                // duration: 애니메이션 길이
                // 만큼 기다렸다가 콜백 (pop) 실행
                onLoaded: (lottieObject) {
                  Future.delayed(Duration(seconds: 3), () {
                    if (lottieContext.mounted) {
                      Navigator.pop(lottieContext);
                    }
                  });
                },
              ),
              Text(
                formatPrice(_reservation!.bidPrice!),
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmArrivalTime() async {
    if (_reservation == null) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ReservationApi().updateReservation(
        reservationId: widget.reservationId,
        arrivalAt: _reservation!.reservationTime,
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
    return _isLoading
        ? Scaffold(body: Center(child: CupertinoActivityIndicator()))
        : Scaffold(
            appBar: AppBar(title: const Text('도착 확정 안내')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '고객님의 도착 예정 시간은 ${DateFormat("HH:mm").format(_reservation!.reservationTime!)}입니다.\n\n'
                    '시간 내에 도착하지 못할 시 매장의 사정에 따라 예약이 취소될 수 있음을 알려드립니다.\n\n'
                    '도착 예정 시간 2시간 전까지는 예약 취소가 가능하나, 이후에는 취소가 불가합니다.', style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _confirmArrivalTime,
                    child: _isSubmitting
                        ? const CupertinoActivityIndicator(color: Colors.black)
                        : const Text('확인'),
                  ),
                ],
              ),
            ),
          );
  }
}
