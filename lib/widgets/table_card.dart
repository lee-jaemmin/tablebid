import 'package:flutter/material.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/widgets/information_window.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final String companyId;
  final List<String> visibleFields;
  final String userId;
  final String userName;
  final DateTime now;
  final DateTime? reservedAt;

  TableCard({
    required this.table,
    required this.companyId,
    required this.visibleFields,
    required this.userId,
    required this. userName,
    required this.now,
    this.reservedAt,
  });

  String _getRemainingTimerText(DateTime? timerEndAt, DateTime now) {
    final remaining = timerEndAt!.toLocal().difference(now);

    if (remaining.isNegative) {
      return '00:00';
    }

    final totalMinutes = (remaining.inSeconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    }

    return '${minutes}분';
  }

  @override
  Widget build(BuildContext context) {
    final purchasesText = table.purchaseSummary == null ? null : table.purchaseSummary!.join(", ");
    final isInUse = table.status == 'inuse';
    final isPassed = table.timerEndAt?.difference(now).isNegative ?? false;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => InformationWindow(
            companyId: companyId,
            table: table,
            userId: userId,
            userName: userName,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isPassed
              ? Colors.red
              : isInUse
              ? Colors.orange.shade100
              : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPassed
                ? Colors.red
                : isInUse
                ? Colors.orange
                : Colors.grey.shade400,
          ),
        ),

        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      table.tablename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (purchasesText != null)
                      const SizedBox(
                        height: 5,
                      ),
                    ...visibleFields
                        .map((field) => _fieldText(field, purchasesText ?? ''))
                        .where((text) => text.isNotEmpty)
                        .map(
                          (text) => Text(
                            text,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            if (isInUse)
              Positioned(
                top: 0,
                right: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                 
                  child: Text(
                    table.registeredAt != null
                        ? DateFormat('HH:mm').format(table.registeredAt!.toLocal())
                        : '등록 시간 없음.',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (table.isReserved == true && table.registeredAt == null)
              Positioned(
                top: 0,
                right: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    reservedAt != null
                        ? DateFormat(
                            'HH:mm',
                          ).format(reservedAt!.toLocal())
                        : '예약 시간 없음.',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (table.timerStartedAt != null && table.timerEndAt != null)
              Positioned(
                top: 0,
                left: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
             
                  child: Text(
                    "⏰${_getRemainingTimerText(table.timerEndAt, now)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fieldText(String field, String purchasesText) {
    switch (field) {
      case 'price':
        return table.totalPrice == 0 ? "" : formatPrice(table.totalPrice);
      case 'persons':
        return table.persons == 0 ? '' : '${table.persons}명';
      case 'staff':
        return '${table.userName ?? ''}';
      case 'remark':
        return '${table.remark}';
      case 'purchases':
        return '${purchasesText}';
      default:
        return '';
    }
  }
}
