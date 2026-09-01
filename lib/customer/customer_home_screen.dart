import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/customer/customer_bid_alert.dart';
import 'package:tablebid/customer/region_chip.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/models/web_socket_event.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/services/websocket_service.dart';
import 'package:tablebid/widgets/company_floor_image.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _regions = ['강남', '이태원', '홍대', '신사/압구정'];
  List<CompanyModel> _companies = [];
  String _selectedRegion = _regions.first;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await CompanyApi().getCompanies();
      if (!mounted) return;
      setState(() {
        _companies = companies;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final visibleCompanies = _companies
        .where((company) => company.region == _selectedRegion)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('매장 선택')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _regions.map((region) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: RegionChip(
                    region: region,
                    isSelected: region == _selectedRegion,
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: user == null
                ? const Center(child: Text('로그인이 필요합니다.'))
                : _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _hasError
                ? Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _hasError = false;
                        });
                        _loadCompanies();
                      },
                      child: const Text('매장 목록 다시 불러오기'),
                    ),
                  )
                : visibleCompanies.isEmpty
                ? const Center(child: Text('해당 지역에 등록된 매장이 없습니다.'))
                : RefreshIndicator(
                    onRefresh: _loadCompanies,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: visibleCompanies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final company = visibleCompanies[index];
                        return Card(
                          child: ListTile(
                            title: Text(company.name),
                            subtitle: Text(company.address),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _CustomerCompanyScreen(
                                  company: company,
                                  userId: user.uid,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCompanyScreen extends StatefulWidget {
  final CompanyModel company;
  final String userId;

  const _CustomerCompanyScreen({required this.company, required this.userId});

  @override
  State<_CustomerCompanyScreen> createState() => _CustomerCompanyScreenState();
}

class _CustomerCompanyScreenState extends State<_CustomerCompanyScreen> {
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
          builder: (context) => _CustomerBidListScreen(
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
                child: _CustomerTableGrid(
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

class _CustomerTableGrid extends StatelessWidget {
  final List<TableModel> tables;
  final ValueChanged<TableModel> onTableTap;

  const _CustomerTableGrid({required this.tables, required this.onTableTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = size.shortestSide > 600;
    final crossAxisCount = isTablet
        ? (isLandscape ? 6 : 4)
        : (isLandscape ? 4 : 3);
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isLandscape ? 1.2 : 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isInUse = table.status == 'inuse';
        final statusText = !table.bidAvailable
            ? '경매 불가'
            : isInUse
            ? '사용 중\n${table.registeredAt == null ? '--:--' : DateFormat('HH:mm').format(table.registeredAt!.toLocal())} 입장'
            : table.hasReservations
            ? '비딩 중'
            : '비딩 참여 가능';
        final color = !table.bidAvailable
            ? Colors.grey[500]
            : isInUse
            ? Colors.green.shade200
            : table.hasReservations
            ? const Color.fromARGB(229, 255, 153, 0)
            : Colors.grey[100];
        return Card(
          color: color,
          child: InkWell(
            onTap: table.bidAvailable ? () => onTableTap(table) : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.tablename,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomerBidListScreen extends StatefulWidget {
  final String companyId;
  final TableModel table;
  final String userId;

  const _CustomerBidListScreen({
    required this.companyId,
    required this.table,
    required this.userId,
  });

  @override
  State<_CustomerBidListScreen> createState() => _CustomerBidListScreenState();
}

class _CustomerBidListScreenState extends State<_CustomerBidListScreen> {
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final reservations = await ReservationApi().getReservationsByTable(
        widget.table.id,
      );
      reservations.sort((a, b) => (b.bidPrice ?? 0).compareTo(a.bidPrice ?? 0));
      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _addBid() async {
    if (_reservations.any((reservation) => reservation.isFixed == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약이 확정된 테이블은 비딩에 참여할 수 없습니다.')),
      );
      return;
    }
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => CustomerBidAlert(
        companyId: widget.companyId,
        table: widget.table,
        userId: widget.userId,
      ),
    );
    if (added == true) await _loadReservations();
  }

  Future<void> _deleteBid(ReservationModel reservation) async {
    if (reservation.createdById != widget.userId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('비딩 취소'),
        content: const Text('내 비딩을 취소하시겠습니까?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    '아니요',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('예', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != widget.userId)
        throw Exception('로그인 정보 없음');
      final token = await user.getIdToken();
      if (token == null || token.isEmpty)
        throw Exception('Firebase ID Token 없음');
      await ReservationApi().deleteReservation(
        reservationId: reservation.id,
        idToken: token,
      );
      await _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비딩 취소 중 오류가 발생했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.table.tablename} 비딩'),
        actions: [
          IconButton(
            onPressed: _addBid,
            tooltip: '비딩 추가',
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _loadReservations,
            tooltip: '새로 고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _hasError
          ? Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _loadReservations();
                },
                child: const Text('비딩 내역 다시 불러오기'),
              ),
            )
          : _reservations.isEmpty
          ? const Center(child: Text('비딩 내역이 없습니다.'))
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: _reservations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final reservation = _reservations[index];
                  final isMine = reservation.createdById == widget.userId;
                  final reservationTime = reservation.reservationTime == null
                      ? ''
                      : DateFormat('HH:mm').format(reservation.reservationTime!);
                  return ListTile(
                    tileColor: isMine ? Colors.green.shade800 : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    title: Text(
                      '${isMine ? reservation.customerName : '다른 참여자'} $reservationTime',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${isMine ? '${reservation.customerPhone}\n' : ''}${formatPrice(reservation.bidPrice ?? 0)}',
                    ),
                    isThreeLine: true,
                    trailing: isMine
                        ? IconButton(
                            tooltip: '내 비딩 삭제',
                            onPressed: () => _deleteBid(reservation),
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
    );
  }
}
