import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/models/web_socket_event.dart';
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
          if (event.type == 'reservation_created') {
            final reservation = ReservationModel.fromJson(event.payload);
            setState(() {
              final index = _tables.indexWhere(
                (table) => table.id == reservation.tableId,
              );
              if (index != -1) {
                _tables[index].isReserved = true;
              }
            });
          }
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
          }
          if (event.type == 'reservation_updated' ||
              event.type == 'reservation_deleted') {
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
        appBar: AppBar(
          title: const Text('예약 관리'),
        ),
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
          title: !_isEditingMode ? const Text('예약 관리') : const Text('경매 시작가 변경'),
           actions: [
            Padding(
              padding: EdgeInsets.all(8),
              child: !_isEditingMode ? 
              IconButton(onPressed: () => setState(() {
                _isEditingMode = !_isEditingMode;
              }),
              icon: Icon(Icons.settings, color: Colors.white,))
              : GestureDetector(
                onTap: () => setState(() {
                _isEditingMode = !_isEditingMode;
              }),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('완료', style: TextStyle(fontSize: 16,),),
                ))
            ),
          ],
          bottom: sections.isEmpty
              ? null
              : TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 4,
                  labelStyle: const TextStyle(fontSize: 16),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                  tabAlignment: TabAlignment.start,
                  isScrollable: true,
                  tabs: sections.map((s) => Tab(text: s)).toList(),
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
                  );
                }).toList(),
              ),
      ),
    );
  }
}
