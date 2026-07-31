import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/history_gridview.dart';

class HistoryScreen extends StatelessWidget {
  final String companyId;

  const HistoryScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TableModel>>(
      future: TableApi().getTables(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('히스토리 화면 로딩 실패: ${snapshot.error}'),
          );
        }

        final tables = snapshot.data ?? [];
        final sections = tables
            .map((table) => table.section)
            .where((section) => section.isNotEmpty)
            .toSet()
            .toList();

        if (sections.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('테이블별 히스토리'),
            ),
            body: const Center(
              child: Text('설정된 섹션이 없습니다.'),
            ),
          );
        }

        sections.sort((a, b) => naturalSortCompare(a, b));

        return DefaultTabController(
          length: sections.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('테이블별 히스토리'),
              bottom: TabBar(
                indicatorWeight: 4,
                labelStyle: TextStyle(fontSize: 16),
                labelPadding: EdgeInsets.symmetric(horizontal: 20.0),
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
                return HistoryGridView(
                  companyId: companyId,
                  tables: sectionTables,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
