import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tablebid/customer/open/public_table_grid.dart';
import 'package:tablebid/customer/route/route_names.dart';
import 'package:tablebid/customer/section_chip.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/public_table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/company_floor_image.dart';

class PublicCompanyScreen extends StatefulWidget {
  final CompanyModel company;

  const PublicCompanyScreen({
    required this.company,
  });

  @override
  State<PublicCompanyScreen> createState() => _CustomerCompanyScreenState();
}

class _CustomerCompanyScreenState extends State<PublicCompanyScreen> {
  List<PublicTableModel> _tables = [];
  bool _isTableLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables({bool showError = true}) async {
    try {
      final tables = await TableApi().getPublicTables(widget.company.id);
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _isTableLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted || !showError) return;
      setState(() {
        _isTableLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _openTable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('회원가입 필요'),
        content: const Text('회원가입이 필요합니다.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.pushNamed(customerSignUpRouteName);
  }

  @override
  Widget build(BuildContext context) {
    if (_isTableLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.company.name)),
        body: const Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.company.name)),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isTableLoading = true;
                _hasError = false;
              });
              _loadTables();
            },
            child: const Text('테이블 다시 불러오기'),
          ),
        ),
      );
    }
    final sections =
        _tables
            .map((table) => table.section)
            .where((section) => section.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => naturalSortCompare(a, b));
    return DefaultTabController(
      key: ValueKey(sections.length),
      length: sections.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.company.name),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                tooltip: '로그인',
                icon: const Icon(Icons.person),
                onPressed: () => context.pushNamed(customerSignUpRouteName),
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
                        children: List.generate(labels.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 56),
                              child: SectionChip(
                                region: labels[index],
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
          physics: NeverScrollableScrollPhysics(),
          children: [
            CompanyFloorImage(
              company: widget.company,
              canAdd: false,
              canReplace: false,
              onCompanyUpdated: (_) {},
            ),
            ...sections.map((section) {
              final tables =
                  _tables.where((table) => table.section == section).toList()
                    ..sort(
                      (a, b) => naturalSortCompare(a.tablename, b.tablename),
                    );
              return PublicTableGrid(tables: tables, onTableTap: _openTable);
            }),
          ],
        ),
      ),
    );
  }
}
