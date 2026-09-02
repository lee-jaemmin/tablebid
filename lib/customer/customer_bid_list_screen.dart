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
