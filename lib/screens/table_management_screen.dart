import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tablebid/customer/section_chip.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/screens/company_entry_screen.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/table_api.dart';

import 'package:tablebid/widgets/admin_table_grid.dart';
import 'package:tablebid/widgets/company_floor_image.dart';

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
  CompanyModel? _company;
  List<TableModel> _tables = [];
  List<String> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetchTables = await TableApi().getTables(widget.companyId);
      final company = await CompanyApi().getCompany(widget.companyId);
      if (!mounted) return;
      setState(() {
        _company = company;
        _tables = fetchTables;
        _sections = company.sections;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로드 중 오류 발생: $e')));
    }
  }

  Future<bool?> _showSectionRenameOptions(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (optionDialogContext) => AlertDialog(
        title: const Text('섹션 수정 옵션'),
        content: const Text(
          '해당 작업은 약 20초 정도 소요됩니다.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                
                  onPressed: () => Navigator.pop(optionDialogContext, true),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManual(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (optionDialogContext) => AlertDialog(
        title: const Text('도움말'),
        content: const Text(
          '<섹션>\n'
          '클릭: 섹션 이동\n길게 누르기: 섹션 수정/삭제\n\n'
          '<테이블>\n'
          '클릭: 테이블 수정\n\n'
          '<이미지>\n'
          '클릭: 이미지 교체',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(optionDialogContext, true),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddSectionDialog() {
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    '취소',
                    
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  
                  onPressed: () async {
                    final newSection = controller.text.trim();

                    if (newSection.isEmpty) return;

                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: dialogContext,
                      barrierColor: Colors.black,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: Lottie.asset('assets/lottie/working_man.json'),
                      ),
                    );
                    try {
                      await CompanyApi().addSection(
                        companyId: widget.companyId,
                        addedSection: newSection,
                      );
                      await _loadData();
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSection(String sectionName) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$sectionName 섹션 삭제'),
        content: const Text(
          '섹션을 삭제하시겠습니까?\n이 섹션에 속한 모든 테이블도 삭제됩니다.\n해당 작업은 20초 정도 소요됩니다.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    '취소',
                  
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.red, side: BorderSide(color: Colors.red)),
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: dialogContext,
                      barrierColor: Colors.black,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: Lottie.asset('assets/lottie/working_man.json'),
                      ),
                    );

                    try {
                      await CompanyApi().deleteSection(
                        companyId: widget.companyId,
                        removedSection: sectionName,
                      );
                      await _loadData();
                      Navigator.pop(context);
                      navigator.pop(context);
                    } catch (e) {
                      print('>>>>> 섹션 삭제 실패: $e');
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

  Future<void> _showRenameSectionDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('섹션 관리'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '새 섹션 이름을 입력하세요'),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _confirmDeleteSection(currentName);
                  },
                  child: const Text(
                    '섹션 삭제',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final newName = controller.text.trim();

                    final renameTables = await _showSectionRenameOptions(
                      dialogContext,
                    );
                    if (renameTables == null || !dialogContext.mounted) return;

                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: dialogContext,
                      barrierColor: Colors.black,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: Lottie.asset('assets/lottie/working_man.json'),
                      ),
                    );

                    try {
                      await CompanyApi().modifySection(
                        companyId: widget.companyId,
                        oldName: currentName,
                        newName: newName,
                      );
                      await _loadData();
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
                  child: const Text('수정'),
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
      return Scaffold(body: Center(child: CupertinoActivityIndicator()));
    } else {
      final company = _company;
      if (company == null) {
        return CompanyEntryScreen(userId: widget.userId);
      }

      final sections = {
        ..._sections,
        ..._tables.map((table) => table.section),
      }.where((section) => section.isNotEmpty).toList();

      sections.sort((a, b) => naturalSortCompare(a, b));

      return DefaultTabController(
        key: ValueKey(sections.length),
        length: sections.length + 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('매장 구성 관리'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IconButton(
                  onPressed: () => _showManual(context),
                  icon: Icon(Icons.help_outline_outlined),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(64),
              child: Builder(
                builder: (tabContext) {
                  final ctrl = DefaultTabController.of(tabContext);
                  final labels = ['전체', ...sections];
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
                          children: [
                            ...List.generate(labels.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 56),
                                  child: GestureDetector(
                                    onLongPress: index == 0
                                        ? null
                                        : () => _showRenameSectionDialog(
                                            sections[index - 1],
                                          ),
                                    child: SectionChip(
                                      region: labels[index],
                                      isSelected: ctrl.index == index,
                                      onTap: () => ctrl.animateTo(index),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            SizedBox(
                              width: 56,
                              child: IconButton(
                                onPressed: () {
                                  ctrl.animateTo(sections.length + 1);
                                  _showAddSectionDialog();
                                },
                                icon: const Icon(
                                  Icons.add_circle_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          body: TabBarView(
            children: [
              CompanyFloorImage(
                company: company,
                canAdd: true,
                canReplace: true,
                onCompanyUpdated: (updatedCompany) {
                  setState(() {
                    _company = updatedCompany;
                    _sections = updatedCompany.sections;
                  });
                },
              ),
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
