import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/section_chip.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/history_gridview.dart';

class HistoryScreen extends StatefulWidget {
  final String companyId;

  const HistoryScreen({super.key, required this.companyId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _endTime = DateTime.now();
    _startTime = _endTime.subtract(const Duration(hours: 3));
  }

  Future<void> _showHistoryRangePicker() async {
    DateTime selectedStartTime = _startTime;
    DateTime selectedEndTime = _endTime;

    final selectedRange = await showCupertinoModalPopup<List<DateTime>>(
      context: context,
      barrierDismissible: false,
      builder: (popupContext) => StatefulBuilder(
        builder: (context, setPopupState) => Container(
          height: MediaQuery.sizeOf(context).height*.7,
          child: Material(
            borderRadius: BorderRadius.circular(50),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '히스토리 조회 기간 설정',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: '시작'),
                        Tab(text: '종료'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.dateAndTime,
                            initialDateTime: selectedStartTime,
                            maximumDate: selectedEndTime,
                            onDateTimeChanged: (newDateTime) {
                              setPopupState(() {
                                selectedStartTime = newDateTime;
                              });
                            },
                          ),
                          CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.dateAndTime,
                            initialDateTime: selectedEndTime,
                            minimumDate: selectedStartTime,
                            onDateTimeChanged: (newDateTime) {
                              setPopupState(() {
                                selectedEndTime = newDateTime;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(popupContext),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(
                                popupContext,
                                [selectedStartTime, selectedEndTime],
                              ),
                              child: const Text('설정'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (selectedRange == null || !mounted) return;
    setState(() {
      _startTime = selectedRange[0];
      _endTime = selectedRange[1];
    });
  }

  Widget _buildCalendarAction() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showHistoryRangePicker,
        child: const Icon(Icons.calendar_month),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TableModel>>(
      future: TableApi().getTables(widget.companyId),
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
              actions: [_buildCalendarAction()],
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
              actions: [_buildCalendarAction()],
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
              children: sections.map((section) {
                final sectionTables = tables
                    .where((table) => table.section == section)
                    .toList();
                return HistoryGridView(
                  companyId: widget.companyId,
                  tables: sectionTables,
                  startTime: _startTime,
                  endTime: _endTime,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
