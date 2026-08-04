import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/screens/company_entry_screen.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/table_api.dart';

import 'package:tablebid/widgets/admin_table_grid.dart';

/// 섹션 관리는 여기서 함.

class TableManagementScreen extends StatefulWidget {
  final String companyId; // 홈 화면에서 넘겨받은 업장 아이디
  final String userId;

  const TableManagementScreen({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  Future<CompanyModel>? _companyFuture;
  List<TableModel> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetchTables = await TableApi().getTables(widget.companyId);
      if (!mounted) return;
      setState(() {
        _companyFuture = CompanyApi().getCompany(widget.companyId);
        _tables = fetchTables;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로드 중 오류 발생: $e')));
    }
  }

  Future<void> _updateSections(
    List<String> sections,
    List<TableModel>? tables,
    String? newName,
  ) async {
    try {
      await CompanyApi().updateCompany(
        companyId: widget.companyId,
        sections: sections,
      );
      if (tables != null) {
        int i = 1;
        for (final table in tables) {
          await TableApi().updateTable(
            tableId: table.id,
            section: newName,
            tableName: '${newName}-$i',
          );
          i += 1;
        }
      } else {
        if (newName != null) {
          for (int i = 0; i < 10; i++) {
            await TableApi().createTable(
              companyId: widget.companyId,
              section: newName,
              tablename: '${newName}-${i + 1}',
            );
          }
        }
      }
      await _loadData();
    } catch (e) {
      print('updateSection: 오류 발생 $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생')));
    }
  }

  void _showAddSectionDialog(List<String> currentSections) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('새 섹션 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '섹션 이름을 입력하세요 (예: Terrace)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              final newSection = controller.text.trim();

              if (newSection.isEmpty) return;

              if (currentSections.contains(newSection)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('이미 존재하는 섹션입니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              try {
                final updatedSections = [...currentSections, newSection];
                await _updateSections(updatedSections, null, newSection);

                navigator.pop(); // 로딩창
                navigator.pop(); // 입력창
              } catch (e) {
                navigator.pop();
                print('>>>>>>>>>>>>>>> e: $e');
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('섹션 추가 실패: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSection(String sectionName, List<String> currentSections) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$sectionName 섹션 삭제'),
        content: const Text('섹션을 삭제하시겠습니까?\n이 섹션에 속한 모든 테이블도 삭제됩니다.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final updatedSections = currentSections
                          .where((section) => section != sectionName)
                          .toList();

                      final toDeleteTables = _tables.where(
                        (table) => table.section == sectionName,
                      );

                      await _updateSections(updatedSections, null, null);
                      for (final table in toDeleteTables) {
                        await TableApi().deleteTable(tableId: table.id);
                      }

                      navigator.pop(); // 로딩창
                      navigator.pop(); // 확인창
                    } catch (e) {
                      navigator.pop();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('섹션 삭제 실패: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRenameSectionDialog(
    String currentName,
    List<String> currentSections,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('섹션 이름 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '새 섹션 이름을 입력하세요'),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final newName = controller.text.trim();

                    if (newName.isEmpty || newName == currentName) return;

                    if (currentSections.contains(newName)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('이미 존재하는 섹션입니다.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final updatedSections = currentSections
                          .map(
                            (section) =>
                                section == currentName ? newName : section,
                          )
                          .toList(); // 기존 섹션에서 바꿀 대상(currentName)찾아서 newName으로 변경.

                      final updatedTables = _tables
                          .where((table) => table.section == currentName)
                          .toList();

                      await _updateSections(
                        updatedSections,
                        updatedTables,
                        newName,
                      );

                      navigator.pop(); // 로딩창
                      navigator.pop(); // 수정창
                    } catch (e) {
                      navigator.pop();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('섹션 수정 실패: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      final company = _companyFuture;
      if (company == null) {
        return CompanyEntryScreen(userId: widget.userId);
      }

      final sections = _tables.map((table) => table.section).toSet().toList();

      sections.sort((a, b) => naturalSortCompare(a, b));

      return DefaultTabController(
        key: ValueKey(sections.length),
        length: sections.length + 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('매장 구성 관리'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('[토글]: 섹션/테이블 이름 변경\n[길게 누르기]: 섹션 삭제'),
              ),
            ],
            bottom: TabBar(
              indicatorWeight: 4,
              labelStyle: const TextStyle(fontSize: 16),
              labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              tabs: [
                ...sections.map(
                  (section) => Tab(
                    child: InkWell(
                      onTap: () => _showRenameSectionDialog(section, sections),
                      onLongPress: () =>
                          _confirmDeleteSection(section, sections),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Text(section),
                      ),
                    ),
                  ),
                ),
                const Tab(icon: Icon(Icons.add, color: Colors.blue)),
              ],
              onTap: (index) {
                if (index == sections.length) {
                  _showAddSectionDialog(sections);
                }
              },
            ),
          ),
          body: TabBarView(
            children: [
              ...sections.map(
                (section) => AdminTableGrid(
                  companyId: widget.companyId,
                  section: section,
                  userId: widget.userId,
                ),
              ),
              const Center(child: Text('새 섹션을 추가하여 매장을 구성하세요.')),
            ],
          ),
        ),
      );
    }
  }
}
