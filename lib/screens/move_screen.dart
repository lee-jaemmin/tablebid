import 'package:flutter/material.dart';
import 'package:tablebid/customer/section_chip.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/move_table_gridview.dart';

class MoveScreen extends StatelessWidget {
  final String companyId;
  final TableModel fromTable;
  final String userId;

  const MoveScreen({
    super.key,
    required this.companyId,
    required this.fromTable,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TableModel>>(
      future: TableApi().getTables(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Scaffold(body: const Center(child: CircularProgressIndicator()));

        if (snapshot.hasError)
          return Center(child: Text('테이블 로딩 실패: ${snapshot.error}'));

        final tables = snapshot.data ?? [];
        final sections = tables
            .map((table) => table.section)
            .where((section) => section.trim().isNotEmpty)
            .toSet()
            .toList();

        sections.sort((a, b) => naturalSortCompare(a, b));

        return DefaultTabController(
          length: sections.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${fromTable.tablename} 이동 위치 선택'),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(64),
                child: Builder(
                  builder: (tabContext) {
                    final ctrl = DefaultTabController.of(tabContext);
                    return AnimatedBuilder(
                      animation: ctrl,
                      builder: (context, child) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: List.generate(sections.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 56),
                                  child: SectionChip(
                                    region: sections[index],
                                    isSelected: ctrl.index == index,
                                    onTap: () => ctrl.animateTo(index),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            body: TabBarView(
              children: sections
                  .map((section) {
                    final sectionTables = tables
                        .where((table) => table.section == section)
                        .toList();
                    return MoveTableGridView(
                      companyId: companyId,
                      fromTable: fromTable,
                      userId: userId,
                      tables: sectionTables,
                    );
                  }) // HomeScreen에서는
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
