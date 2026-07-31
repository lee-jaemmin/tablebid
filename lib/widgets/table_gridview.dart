import 'package:flutter/material.dart';
import 'package:tablebid/models/table_model.dart';
import 'dart:async';
import 'package:tablebid/widgets/table_card.dart';

class TableGridView extends StatefulWidget {
  final String companyId;
  final List<ValueNotifier<TableModel>> tableNotifiers;
  final List<String> visibleFields;
  final String userId;
  final String userName;
  final ScrollPhysics? physics;

  TableGridView({
    super.key,
    required this.companyId,
    required this.tableNotifiers,
    required this.visibleFields,
    required this.userId,
    required this.userName,
    this.physics,
  });

  @override
  State<TableGridView> createState() => _TableGridViewState();
}
class _TableGridViewState extends State<TableGridView> {
  bool _isLoading = false;
  Timer? _ticker;
  DateTime _now = DateTime.now().toLocal();
  // 타이머를 카드마다 만들면 비효율.
  // 부모에서 현재 시간을 30초마다 넘겨주는 방식
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now().toLocal();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final isTablet = size.shortestSide > 600;
    final isLandScape = orientation == Orientation.landscape;

    int crossAxisCount = isTablet
        ? (isLandScape ? 6 : 4)
        : (isLandScape ? 4 : 3);

    return _isLoading
        ? const Center(
            child: const CircularProgressIndicator(),
          )
        : GridView.builder(
            physics: widget.physics,
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: isLandScape ? 1.2 : 1.0,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: widget.tableNotifiers.length,
            itemBuilder: (context, index) {
              final tableNotifier = widget.tableNotifiers[index];
              return ValueListenableBuilder<TableModel>(
                // 'ValueNotifier' 변경 감지
                // 변경 감지 시 builder rebuild
                valueListenable: tableNotifier,
                builder: (context, table, _) {
                  return TableCard(
                    table: table,                    
                    companyId: widget.companyId,
                    visibleFields: widget.visibleFields,
                    userId: widget.userId,
                    userName: widget.userName,
                    reservedAt: table.reservedAt,
                    now: _now,
                  );
                },
              );
            },
          );
  }
}
