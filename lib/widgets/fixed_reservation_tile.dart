import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class FixedReservationTile extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onCheckIn;
  final VoidCallback onCancel;

  const FixedReservationTile({
    super.key,
    required this.reservation,
    required this.onCheckIn,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '확정된 예약',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            title: Text(
              '${reservation.customerName} ${reservation.reservationTime == null ? '' : DateFormat('HH:mm').format(reservation.reservationTime!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${reservation.customerPhone}\n${formatPrice(reservation.bidPrice!)}',
            ),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: '입장',
                  onPressed: onCheckIn,
                  icon: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  tooltip: '취소',
                  onPressed: onCancel,
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
