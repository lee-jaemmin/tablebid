import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/customer/customer_bid_alert.dart';
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class CustomerBidListScreen extends StatefulWidget {
  final String companyId;
  final TableModel table;
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
    final fixedReservationIndex = _reservations.indexWhere(
      (reservation) => reservation.isFixed == true,
    );
    final fixedReservation = fixedReservationIndex == -1
        ? null
        : _reservations[fixedReservationIndex];
    final List<ReservationModel> leftBidList = fixedReservationIndex == -1
        ? _reservations
        : ([..._reservations]..removeAt(fixedReservationIndex));
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fixedReservation != null)
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(60, 32),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(8),
                                ),
                              ),
                              child: const Text('확정된 예약', style: TextStyle(fontSize: 12)),
                            ),
                            _CustomerBidTile(
                              reservation: fixedReservation,
                              userId: widget.userId,
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
                              : Colors.grey,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(8),
                          ),
                        ),
                        child: Text(
                          fixedReservation == null ? '비딩 중' : '비딩 마감',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: leftBidList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final reservation = leftBidList[index];
                        return _CustomerBidTile(
                          reservation: reservation,
                          userId: widget.userId,
                          onDelete: reservation.createdById == widget.userId
                              ? () => _deleteBid(reservation)
                              : null,
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
  final ReservationModel reservation;
  final String userId;
  final VoidCallback? onDelete;

  const _CustomerBidTile({
    required this.reservation,
    required this.userId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = reservation.createdById == userId;
    final reservationTime = reservation.reservationTime == null
        ? ''
        : DateFormat('HH:mm').format(reservation.reservationTime!);
    return ListTile(
      tileColor: isMine ?  Colors.blue.withValues(alpha: 0.16) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      title: Text(
        '${isMine ? reservation.customerName : '다른 참여자'} $reservationTime',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${isMine ? '${reservation.customerPhone}\n' : ''}${formatPrice(reservation.bidPrice ?? 0)}',
      ),
      isThreeLine: true,
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: '내 비딩 삭제',
              onPressed: onDelete,
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
    );
  }
}
