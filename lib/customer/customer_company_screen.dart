import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tablebid/customer/customer_bid_alert.dart';
import 'package:tablebid/customer/route/route_names.dart';
import 'package:tablebid/customer/customer_table_grid.dart';
import 'package:tablebid/customer/section_chip.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/models/web_socket_event.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/services/websocket_service.dart';
import 'package:tablebid/widgets/company_floor_image.dart';

class CustomerCompanyScreen extends StatefulWidget {
  final CompanyModel company;
  final String userId;
  final Future<void> Function(TableModel)? onTableSelected;

  const CustomerCompanyScreen({
    required this.company,
    required this.userId,
    this.onTableSelected,
  });

  @override
  State<CustomerCompanyScreen> createState() => _CustomerCompanyScreenState();
}

class _CustomerCompanyScreenState extends State<CustomerCompanyScreen> {
  List<TableModel> _tables = [];
  StreamSubscription<WebSocketEvent>? _webSocketSubscription;
  UserModel? _user;
  bool _isTableLoading = true;
  bool _isUserLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _loadUser();
    _subscribeToWebSocket();
  }

  Future<void> _loadTables({bool showError = true}) async {
    try {
      final tables = await TableApi().getTables(widget.company.id);
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

  Future<void> _refresh() async {
    await Future.wait([_checkUnder(), _loadTables(), _loadUser()]);
  }

  Future<void> _checkUnder() async {
    try {
      final result = await ReservationApi().reservationUnder();
      if (!mounted) return;
      if (result != null) {
        context.goNamed(
          customerArrivalRouteName,
          pathParameters: {'reservationId': result.id.toString()},
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await UserApi().getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _isUserLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUserLoading = false;
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
    final user = _user;
    if (user == null) {
      return;
    }
    if (!user.phoneVerified) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('전화 번호 인증 필요'),
          content: Text('설정 > 번호 인증을 탭하여 전화 번호 인증을 진행해주세요.'),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text('확인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      return;
    }
    if (!table.bidAvailable) return;
    if (widget.onTableSelected != null) {
      await widget.onTableSelected!(table);
      if (!mounted) return;
      await _loadTables(showError: false);
      return;
    }
    if (table.hasReservations) {
      await context.pushNamed(
        customerBidListRouteName,
        pathParameters: {'companyId': widget.company.id, 'tableId': table.id},
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
    if (_isUserLoading || _isTableLoading) {
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
                _isUserLoading = true;
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
            IconButton(
              tooltip: '새로고침',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
            IconButton(
              tooltip: '설정',
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await context.pushNamed(customerSettingsRouteName);
                if (!mounted) return;
                await _loadUser();
              },
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
              return RefreshIndicator(
                onRefresh: _refresh,
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
