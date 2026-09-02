import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/customer_bid_alert.dart';
import 'package:tablebid/customer/customer_bid_list_screen.dart';
import 'package:tablebid/customer/customer_table_grid.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/models/web_socket_event.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/services/websocket_service.dart';
import 'package:tablebid/widgets/company_floor_image.dart';

class CustomerCompanyScreen extends StatefulWidget {
  final CompanyModel company;
  final String userId;

  const CustomerCompanyScreen({required this.company, required this.userId});

  @override
  State<CustomerCompanyScreen> createState() => _CustomerCompanyScreenState();
}

class _CustomerCompanyScreenState extends State<CustomerCompanyScreen> {
  List<TableModel> _tables = [];
  StreamSubscription<WebSocketEvent>? _webSocketSubscription;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _subscribeToWebSocket();
  }

  Future<void> _loadTables({bool showError = true}) async {
    try {
      final tables = await TableApi().getTables(widget.company.id);
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted || !showError) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _subscribeToWebSocket() {
    final service = WebsocketService.instance;
    _webSocketSubscription = service.events.listen((event) {
      if (!mounted) return;
      try {
        if (event.type == 'table_updated') {
          final updatedTable = TableModel.fromJson(event.payload);
          final index = _tables.indexWhere(
            (table) => table.id == updatedTable.id,
          );
          if (index == -1) return;
          setState(() {
            _tables[index] = updatedTable;
          });
        } else if (event.type == 'reservation_created' ||
            event.type == 'reservation_updated' ||
            event.type == 'reservation_deleted') {
          _loadTables(showError: false);
        }
      } catch (e) {
        _loadTables(showError: false);
      }
    });
    service.connect(widget.company.id);
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openTable(TableModel table) async {
    if (!table.bidAvailable) return;
    if (table.hasReservations) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerBidListScreen(
            companyId: widget.company.id,
            table: table,
            userId: widget.userId,
          ),
        ),
      );
    } else {
      await showDialog<bool>(
        context: context,
        builder: (context) => CustomerBidAlert(
          companyId: widget.company.id,
          table: table,
          userId: widget.userId,
        ),
      );
    }
    await _loadTables(showError: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                _isLoading = true;
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
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontSize: 16),
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            tabs: [
              const Tab(text: '전체'),
              ...sections.map((section) => Tab(text: section)),
            ],
          ),
        ),
        body: TabBarView(
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
              return RefreshIndicator(
                onRefresh: _loadTables,
                child: CustomerTableGrid(
                  tables: tables,
                  onTableTap: _openTable,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}