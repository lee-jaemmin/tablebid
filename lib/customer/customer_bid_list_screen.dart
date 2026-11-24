import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/customer/customer_bid_alert.dart';
import 'package:tablebid/customer/customer_bid_modify_alert.dart';
import 'package:tablebid/methods/reservation_phone_number.dart';
import 'package:tablebid/models/customer_table_model.dart';
import 'package:tablebid/models/customer_reservation_model.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/models/web_socket_event.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/services/my_bid_api.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/services/websocket_service.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class CustomerBidListScreen extends StatefulWidget {
  final String companyId;
  final CustomerTableModel table;
  final String userId;

  const CustomerBidListScreen({
    required this.companyId,
    required this.table,
    required this.userId,
  });

  @override
  State<CustomerBidListScreen> createState() => _CustomerBidListScreenState();
}

class _CustomerBidListScreenState extends State<CustomerBidListScreen> {
  StreamSubscription<WebSocketEvent>? _webSocketSubscription;
  List<CustomerReservationModel> _reservations = [];
  Set<int> _myReservationIds = {};
  Future<void> _reservationUpdates = Future<void>.value();
  bool _isLoading = true;
  bool _hasError = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _subscribeToWebSocket();
  }

  Future<void> _loadReservations() {
    _reservationUpdates = _reservationUpdates.then((_) => _fetchReservations());
    return _reservationUpdates;
  }

  Future<void> _fetchReservations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = await UserApi().getUser(widget.userId);
      final reservations = await ReservationApi().getCustomerReservationsByTable(
        widget.table.id,
      );
      final myBids = await MyBidApi().getMyBids();
      reservations.sort((a, b) => (b.bidPrice ?? 0).compareTo(a.bidPrice ?? 0));
      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _myReservationIds = myBids.map((item) => item.id).toSet();
        _user = user;
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

  void _subscribeToWebSocket() {
    final service = WebsocketService.instance;
    _webSocketSubscription = service.events.listen((event) {
      if (!mounted || event.payload['table_id'] != widget.table.id) return;
      if (event.type != 'reservation_updated' &&
          event.type != 'reservation_deleted') return;
      _reservationUpdates = _reservationUpdates.then((_) => _applyReservationEvent(event));
    });
    service.connect(widget.companyId, role: WebSocketRole.customer);
  }

  Future<void> _applyReservationEvent(WebSocketEvent event) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final reservation = CustomerReservationModel.fromJson(event.payload);
      final myBids = await MyBidApi().getMyBids();
      if (!mounted) return;
      setState(() {
        if (event.type == 'reservation_deleted') {
          _reservations.removeWhere((item) => item.id == reservation.id);
        } else {
          final index = _reservations.indexWhere((item) => item.id == reservation.id);
          if (index == -1) {
            _reservations.add(reservation);
          } else {
            _reservations[index] = reservation;
          }
          _reservations.sort((a, b) => (b.bidPrice ?? 0).compareTo(a.bidPrice ?? 0));
        }
        _myReservationIds = myBids.map((item) => item.id).toSet();
        _isLoading = false;
      });
    } catch (e) {
      print('고객 예약 실시간 업데이트 처리 실패: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  String _customerName(int id) => _user!.userName;

  String _customerPhone(int id) =>
      toReservationDisplayPhone(_user!.phonenumber ?? '');

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _addBid() async {
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

  Future<void> _deleteBid(CustomerReservationModel reservation) async {
    if (!_myReservationIds.contains(reservation.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('입찰 취소'),
        content: const Text('내 입찰을 취소하시겠습니까?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('아니요'),
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
      ).showSnackBar(const SnackBar(content: Text('입찰 취소 중 오류가 발생했습니다.')));
    }
  }

  Future<void> _modifyBid(CustomerReservationModel reservation) async {
    if (!_myReservationIds.contains(reservation.id)) return;
    await showDialog<bool>(
      context: context,
      builder: (context) => CustomerBidModifyAlert(
        companyId: widget.companyId,
        table: widget.table,
        reservationId: reservation.id,
        userId: widget.userId,
        reservationTime: reservation.reservationTime,
        customerName: _customerName(reservation.id),
        phonenumber: _customerPhone(reservation.id),
        bidPrice: reservation.bidPrice,
        isFixed: reservation.isFixed,
      ),
    );
    if (!mounted) return;
    await _loadReservations();
  }

  @override
  Widget build(BuildContext context) {
    final fixedReservationIndex = _reservations.indexWhere(
      (reservation) => reservation.isFixed == true,
    );
    final fixedReservation = fixedReservationIndex == -1
        ? null
        : _reservations[fixedReservationIndex];
    final isFixedMine = fixedReservation != null &&
        _myReservationIds.contains(fixedReservation.id);
    final List<CustomerReservationModel> leftBidList = fixedReservationIndex == -1
        ? _reservations
        : ([..._reservations]..removeAt(fixedReservationIndex));
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.table.tablename}번 경매'),
        actions: [
          IconButton(
            onPressed: _loadReservations,
            tooltip: '새로 고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: _addBid,
          tooltip: '입찰 추가',
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                child: const Text('입찰 내역 다시 불러오기'),
              ),
            )
          : _reservations.isEmpty
          ? const Center(child: Text('입찰 내역이 없습니다.'))
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 88),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fixedReservation != null)
                      Container(
                        color: Colors.blue.withValues(alpha: 0.32),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilledButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(60, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    8,
                                  ),
                                ),
                              ),
                              child: const Text(
                                '확정',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              onTap: isFixedMine
                                  ? () => _modifyBid(fixedReservation)
                                  : null,
                              title: Text(
                                isFixedMine
                                    ? _customerName(fixedReservation.id)
                                    : '다른 참여자',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${isFixedMine ? '${_customerPhone(fixedReservation.id)}\n' : ''}${formatPrice(fixedReservation.bidPrice ?? 0)}',
                              ),
                              isThreeLine: isFixedMine,
                            ),
                          ],
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: fixedReservation == null
                              ? const Color.fromARGB(229, 255, 153, 0)
                              : Colors.black,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(8),
                          ),
                        ),
                        child: Text(
                          fixedReservation == null ? '입찰 중' : '경매 마감',
                          style: TextStyle(
                            fontSize: 12,
                            color: fixedReservation == null
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: leftBidList.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reservation = leftBidList[index];
                        return _CustomerBidTile(
                          reservation: reservation,
                          isMine: _myReservationIds.contains(reservation.id),
                          customerName: _myReservationIds.contains(reservation.id)
                              ? _customerName(reservation.id) : '',
                          customerPhone: _myReservationIds.contains(reservation.id)
                              ? _customerPhone(reservation.id) : '',
                          onTap: _myReservationIds.contains(reservation.id)
                              ? () => _modifyBid(reservation) : null,
                          onDelete: _myReservationIds.contains(reservation.id)
                              ? () => _deleteBid(reservation) : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CustomerBidTile extends StatelessWidget {
  final CustomerReservationModel reservation;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isMine;
  final String customerName;
  final String customerPhone;

  const _CustomerBidTile({
    required this.reservation,
    required this.isMine,
    required this.customerName,
    required this.customerPhone,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final reservationTime = reservation.reservationTime == null
        ? ''
        : DateFormat('HH:mm').format(reservation.reservationTime!);
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(16),
      ),
      onTap: onTap,
      tileColor: isMine
          ? Colors.blue.withValues(alpha: 0.24)
          : Colors.grey.shade400,
      contentPadding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 12,
        top: 6,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMine)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(48, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(8),
                  ),
                ),
                child: const Text('내 입찰', style: TextStyle(fontSize: 12)),
              ),
            ),

          Text(
            '${isMine ? customerName : '다른 참여자'} $reservationTime',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      subtitle: Text(
        '${isMine ? '${customerPhone}\n' : '\n'}${formatPrice(reservation.bidPrice ?? 0)}',
      ),
      isThreeLine: true,
    );
  }
}
