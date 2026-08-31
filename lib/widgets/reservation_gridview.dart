import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/widgets/reservation_card.dart';

class ReservationGridView extends StatelessWidget {
  final String companyId;
  final List<TableModel> tables;
  final String userId;
  final bool isEditingMode;

  ReservationGridView({
    required this.companyId,
    required this.tables,
    required this.userId,
    required this.isEditingMode, 
  });

  @override
  Widget build(BuildContext context) {
    tables.sort((a, b)=>naturalSortCompare(a.tablename, b.tablename));
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final isTablet = size.shortestSide > 600;
    final isLandScape = orientation == Orientation.landscape;

    int crossAxisCount = isTablet
        ? (isLandScape ? 6 : 4)
        : (isLandScape ? 4 : 3);

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isLandScape ? 1.2 : 1.0,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return ReservationCard(
          companyId: companyId,
          table: table,
          userId: userId,
          isEditingMode: isEditingMode,
        );
      },
    );
  }
}
