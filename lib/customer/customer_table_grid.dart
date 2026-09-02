import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/models/table_model.dart';

class CustomerTableGrid extends StatelessWidget {
  final List<TableModel> tables;
  final ValueChanged<TableModel> onTableTap;

  const CustomerTableGrid({required this.tables, required this.onTableTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = size.shortestSide > 600;
    final crossAxisCount = isTablet
        ? (isLandscape ? 6 : 4)
        : (isLandscape ? 4 : 3);
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isLandscape ? 1.2 : 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isInUse = table.status == 'inuse';
        final statusText = !table.bidAvailable
            ? '경매 불가'
            : isInUse
            ? '사용 중\n${table.registeredAt == null ? '--:--' : DateFormat('HH:mm').format(table.registeredAt!.toLocal())} 입장'
            : table.hasReservations
            ? '비딩 중'
            : '비딩 참여 가능';
        final color = !table.bidAvailable
            ? Colors.grey[500]
            : isInUse
            ? Colors.green.shade200
            : table.hasReservations
            ? const Color.fromARGB(229, 255, 153, 0)
            : Colors.grey[100];
        return Card(
          color: color,
          child: InkWell(
            onTap: table.bidAvailable ? () => onTableTap(table) : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.tablename,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}