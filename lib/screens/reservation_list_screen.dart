import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/models/reservation_purchase_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/services/reservation_purchase_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';
import 'package:tablebid/widgets/reservation_alert.dart';

class ReservationListScreen extends StatefulWidget {
  final String companyId;
  final TableModel table;
  final String userId;

  ReservationListScreen({
    super.key,
    required this.companyId,
    required this.table,
    required this.userId,
  });

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  List<ReservationModel> _reservations = [];
  // Map<int, List<ReservationPurchaseModel>> _resPurchasesByReservation = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    final reservations = await ReservationApi().getReservationsByTable(
      widget.table.id,
    );

    // final Map<int, List<ReservationPurchaseModel>> purchasesMap = {};
    // for (final reservation in reservations) {
    //   final purchases = await ReservationPurchaseApi()
    //       .getResPurchasesByReservation(reservation.id);
    //   purchasesMap[reservation.id] = purchases;
    // }

    if (!mounted) return;

    setState(() {
      _reservations = reservations;
      // _resPurchasesByReservation = purchasesMap;
      _isLoading = false;
    });
  }

  Future<void> _showReservationAlert(
    BuildContext context,
    TableModel table,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ReservationAlert(
        companyId: widget.companyId,
        table: table,
        userId: widget.userId,
      ),
    );
    if(!mounted) return;
    setState(() {
      loadData();
    });
  }

  Future<void> _admitReservation(
    BuildContext context,
    TableModel table,
    ReservationModel reservation,
  ) async {
    if (table.status == 'inuse') {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('입장 불가'),
          content: Text(
            '${table.tablename}번 테이블이 현재 사용 중입니다.\n기존 손님을 먼저 아웃 처리해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      return;
    }
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('예약 입장'),
            content: Text(
              '${table.tablename}번 테이블에 ${reservation.customerName} 손님을 등록할까요?',
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: Colors.white,
                        )
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('아니오', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '입장',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;
    try {
      print("ReservationId: ${reservation.id}");
      await ReservationApi().reservationCheckIn(reservationId: reservation.id);
    } catch (e) {
      print('❌ ReservationCheckIn 입장 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('입장 처리 중 오류 발생')));
    }
    await loadData();
  }

  Future<void> _removeReservation(
    BuildContext context,
    TableModel table,
    ReservationModel reservation,
  ) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('예약 취소'),
            content: const Text('예약을 취소하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('아니오', style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '네',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;
    try {
      await ReservationApi().deleteReservation(reservationId: reservation.id);
    } catch (e) {
      print('❌ 예약 내역 삭제 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약 삭제 중 오류 발생')));
    }
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.table.tablename} 예약'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Tooltip(
              message: "예약 추가",
              child: IconButton(
                onPressed: () => _showReservationAlert(context, widget.table),
                icon: Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _reservations.isEmpty
          ? const Center(child: Text('예약 없음'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _reservations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final reservation = _reservations[index];
                // final purchases =
                //     _resPurchasesByReservation[reservation.id] ?? [];
                // final purchaseText = purchases
                //     .map(
                //       (purchase) => "${purchase.itemName} ${purchase.quantity}",
                //     )
                //     .join(', ');
                // final resTotalPrice = purchases.fold<int>(
                //   0,
                //   (sum, item) => (sum += item.unitPrice * item.quantity),
                // );
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  title: Text(
                    '${reservation.customerName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${reservation.customerPhone}\n${formatPrice(reservation.bidPrice!)}'),
                  // subtitle: Text(
                  //   '${purchaseText} : ${formatPrice(resTotalPrice)}',
                  // ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: '입장',
                        onPressed: () => _admitReservation(
                          context,
                          widget.table,
                          reservation,
                        ),
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        tooltip: '취소',
                        onPressed: () => _removeReservation(
                          context,
                          widget.table,
                          reservation,
                        ),
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
