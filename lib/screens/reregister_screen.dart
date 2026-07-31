import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_history_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/reregister_table_gridview.dart';

class ReregisterScreen extends StatelessWidget {
  final String companyId;
  final TableHistoryModel historyData; // 히스토리에서 넘어온 데이터]

  const ReregisterScreen({
    super.key,
    required this.companyId,
    required this.historyData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TableModel>>(
      future: TableApi().getTables(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        final tables = snapshot.data ?? [];
        final sections = tables
            .map((table) => table.section)
            .where((section) => section.isNotEmpty)
            .toSet()
            .toList();

        sections.sort((a, b) => naturalSortCompare(a, b));

        return DefaultTabController(
          length: sections.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('재등록 위치 선택'),
              bottom: TabBar(
                indicatorWeight: 4,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: sections.map((s) => Tab(text: s)).toList(),
              ),
            ),
            body: TabBarView(
              children: sections.map((section) {
                final sectionTables = tables
                    .where((table) => table.section == section)
                    .toList();
                return ReregisterTableGridView(
                  companyId: companyId,
                  tables: sectionTables,
                  historyData: historyData,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
