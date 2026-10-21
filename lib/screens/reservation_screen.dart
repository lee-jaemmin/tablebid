import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/section_chip.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/models/web_socket_event.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/services/websocket_service.dart';
import 'package:tablebid/widgets/reservation_gridview.dart';

class ReservationScreen extends StatefulWidget {
  final String companyId;
  final String userId;
  const ReservationScreen({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  List<TableModel> _tables = [];
  StreamSubscription<WebSocketEvent>? _webSocketEventSubscription;
  bool isLoading = true;
  bool _hasLoadError = false;
  bool _isEditingMode = false;

  @override
  void initState() {
    super.initState();
    _subscribeToWebSocket();
    _loadTables(widget.companyId); // 여기서 실행 시 widgetbinding필요 x
  }

  Future<void> _loadTables(
    String companyId, {
    bool showErrorState = true,
  }) async {
    try {
      final tables = await TableApi().getTables(companyId);
      if (!mounted) return;
      setState(() {
        _tables = tables;
        isLoading = false;
        _hasLoadError = false;
      });
    } catch (e) {
      print("getTable 실패: $e");
      if (!mounted) return;
      if (showErrorState) {
        setState(() {
          isLoading = false;
          _hasLoadError = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('테이블을 불러오는 데 실패했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _subscribeToWebSocket() {
    final service = WebsocketService.instance;
    _webSocketEventSubscription = service.events.listen(
      (event) {
        if (!mounted) return;
        try {
          if (event.type == 'table_updated') {
            final updatedTable = TableModel.fromJson(event.payload);
            setState(() {
              final index = _tables.indexWhere(
                (table) => table.id == updatedTable.id,
              );
              if (index != -1) {
                _tables[index] = updatedTable;
              }
            });
            _loadTables(widget.companyId, showErrorState: false);
          }
        } catch (e) {
          print('예약 실시간 업데이트 처리 실패: $e');
        }
      },
      onError: (error) {
        print('웹소켓 이벤트 처리 실패: $error');
      },
    );
    service.connect(widget.companyId);
  }

  Future<void> allowAllBids() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('모든 테이블의 최상위 입찰을 수락하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('예'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (_) => const Center(child: CupertinoActivityIndicator()),
      barrierDismissible: false,
    );

    try {
      await ReservationApi().allowAllBids(widget.companyId);
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      print('>>>>>>>>>>>>>> 전체 수락 실패: $e');
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('전체 수락 실패: $e')),
      );
    }
  }

  Future<void> _showCupertinoTimerPicker(BuildContext context) async {
    final now = DateTime.now();
    final threshold = now.add(const Duration(minutes: 1));
    final minimumDateTime =
        DateTime(
          threshold.year,
          threshold.month,
          threshold.day,
          threshold.hour,
          threshold.minute,
        ).add(
          threshold.second > 0 ||
                  threshold.millisecond > 0 ||
                  threshold.microsecond > 0
              ? const Duration(minutes: 1)
              : Duration.zero,
        );
    final initialThreshold = now.add(const Duration(hours: 1));
    final initialDateTime =
        DateTime(
          initialThreshold.year,
          initialThreshold.month,
          initialThreshold.day,
          initialThreshold.hour,
          initialThreshold.minute,
        ).add(
          initialThreshold.second > 0 ||
                  initialThreshold.millisecond > 0 ||
                  initialThreshold.microsecond > 0
              ? const Duration(minutes: 1)
              : Duration.zero,
        );
    DateTime selectedDateTime = initialDateTime;
    final confirmedDateTime = await showCupertinoModalPopup<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          height: 450,
          child: Material(
            borderRadius: BorderRadius.circular(50),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '테이블 마감 시간 일괄 설정',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      initialDateTime: initialDateTime,
                      minimumDate: minimumDateTime,
                      onDateTimeChanged: (DateTime newDateTime) {
                        selectedDateTime = newDateTime;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(context, selectedDateTime),
                            child: const Text('확인'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmedDateTime != null) {
      selectedDateTime = confirmedDateTime;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CupertinoActivityIndicator()),
      );
      // 타이머 db로 보내기
      try {
        await CompanyApi().setTablesBidEndAt(
          widget.companyId,
          selectedDateTime,
        );
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context); // 꼼수. 실시간 로딩하기 싫어서 일부러 홈으로 보냄.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("경매 마감 시간 일괄 설정 완료"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        if (!mounted) return;
        if (e.toString().contains("Table already reserved")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('경매 진행 중인 테이블이 있어 경매 마감 시간 일괄 설정에 실패하였습니다.'),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _webSocketEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: const Center(child: CupertinoActivityIndicator()));
    }
    if (_hasLoadError) {
      return Scaffold(
        appBar: AppBar(title: const Text('경매(예약) 관리')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                _hasLoadError = false;
              });
              _loadTables(widget.companyId);
            },
            child: const Text('다시 시도'),
          ),
        ),
      );
    }

    final sections = _tables
        .map((table) => table.section)
        .where((section) => section.isNotEmpty)
        .toSet()
        .toList();

    sections.sort((a, b) => naturalSortCompare(a, b));

    return DefaultTabController(
      key: ValueKey(sections.length),
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: !_isEditingMode,
          title: !_isEditingMode
              ? const Text('경매(예약) 관리')
              : const Text('경매 설정 변경'),
          actions: [
            if (!_isEditingMode)
              IconButton(
                onPressed: () => allowAllBids(),
                icon: const Icon(Icons.check),
              ),
            _isEditingMode
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                    child: IconButton(
                      onPressed: () => _showCupertinoTimerPicker(context),
                      icon: Icon(Icons.timer),
                    ),
                  )
                : SizedBox.shrink(),
            Padding(
              padding: EdgeInsets.all(8),
              child: !_isEditingMode
                  ? IconButton(
                      onPressed: () => setState(() {
                        _isEditingMode = !_isEditingMode;
                      }),
                      icon: Icon(Icons.settings),
                    )
                  : GestureDetector(
                      onTap: () => setState(() {
                        _isEditingMode = !_isEditingMode;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 12.0,
                          left: 8.0,
                          top: 8.0,
                          bottom: 8.0,
                        ),
                        child: Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
          bottom: sections.isEmpty
              ? null
              : PreferredSize(
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
        body: sections.isEmpty
            ? const Center(child: Text('섹션이 없습니다.'))
            : TabBarView(
                children: sections.map((section) {
                  final sectionTables = _tables
                      .where((table) => table.section == section)
                      .toList();
                  return ReservationGridView(
                    companyId: widget.companyId,
                    tables: sectionTables,
                    userId: widget.userId,
                    isEditingMode: _isEditingMode,
                    onTableChanged: (updatedTable) {
                      final index = _tables.indexWhere(
                        (table) => table.id == updatedTable.id,
                      );
                      if (index != -1) {
                        setState(() {
                          _tables[index] = updatedTable;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }
}
