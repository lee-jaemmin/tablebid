import 'package:flutter/material.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/screens/reservation_list_screen.dart';
import 'package:tablebid/widgets/reservation_alert.dart';
import 'package:intl/intl.dart'; // DateTime포맷팅용

class ReservationCard extends StatelessWidget {
  final String companyId;
  final TableModel table;
  final String userId;

  ReservationCard({
    super.key,
    required this.companyId,
    required this.table,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    bool hasReservation;
    if (table.hasReservations == true) {
      hasReservation = true;
    } else {
      hasReservation = false;
    }
    return Card(
      // 예약이 있으면 하늘색, 없으면 하얀색 계열
      color: hasReservation ? Colors.blue[300] : Colors.grey[100],
      elevation: hasReservation ? 4 : 1,
      child: InkWell(
        onTap: () {
          if (!hasReservation) {
            showDialog(
              context: context,
              builder: (context) => ReservationAlert(
                companyId: companyId,
                table: table,
                userId: userId,
              ),
            );
          } else
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationListScreen(
                  companyId: companyId,
                  table: table,
                  userId: userId,
                ),
              ),
            );
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.tablename,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black
                ),
              ),
              const SizedBox(height: 8),
              if (hasReservation)
                Text(
                  DateFormat(
                    'HH:mm',
                  ).format(table.reservedAt!.toLocal()),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              else
                const Text(
                  '예약 없음',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
