import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:tablebid/widgets/fixed_reservation_tile.dart';
import 'package:tablebid/widgets/price_formatter.dart';
import 'package:tablebid/widgets/reservation_alert.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/widgets/reservation_modify_alert.dart';
// import 'package:tablebid/services/reservation_purchase_api.dart';
// import 'package:tablebid/models/reservation_purchase_model.dart';

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
  bool _tableReserved = false;

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
    reservations.sort((a, b) => (b.bidPrice!).compareTo(a.bidPrice!));

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
      _tableReserved = _reservations.any(
        (reservation) => reservation.isFixed == true,
      );
    });
  }

  Future<void> _showReservationAlert(
    BuildContext context,
    TableModel table,
  ) async {
    if(_tableReserved == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약이 확정된 테이블은 비딩에 참여할 수 없습니다.'), behavior: SnackBarBehavior.floating,));
      return;
    }
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ReservationAlert(
        companyId: widget.companyId,
        table: table,
        userId: widget.userId,
      ),
    );
    if (confirm == false) return;
    if (!mounted) return;
    setState(() {
      loadData();
    });
  }

  Future<void> _showReservationModifyAlert(
    BuildContext context,
    TableModel table,
    int reservationId,
    DateTime? reservationTime,
    String? customerName,
    String? phonenumber,
    int? bidPrice,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ReservationModifyAlert(
        companyId: widget.companyId,
        table: table,
        reservationId: reservationId,
        customerName: customerName,
        userId: widget.userId,
        reservationTime: reservationTime,
        phonenumber: phonenumber,
        bidPrice: bidPrice,
      ),
    );
    if (confirm == false) return;
    if (!mounted) return;
    setState(() {
      loadData();
    });
  }

  Future<void> _fixReservation(
    BuildContext context,
    TableModel table,
    ReservationModel reservation,
  ) async {
    if (_tableReserved == true) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약 확정 불가'),
          content: Text(
            '${table.tablename}번 테이블의 확정된 예약이 이미 존재합니다.\n해당 예약을 취소해주세요.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
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
            title: const Text('예약 확정'),
            content: Text(
              '${table.tablename}번 테이블 예약을 이 예약으로 확정하시겠습니까?\n예약이 확정된 테이블은 더 이상 비딩을 받을 수 없습니다.',
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        '아니오',
                        style: TextStyle(color: Colors.white),
                      ),
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
                        '예',
                        style: TextStyle(color: Colors.black),
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
    showDialog(
      context: context,
      builder: (context) => CupertinoActivityIndicator(),
      barrierDismissible: false,
    );
    try {
      print("ReservationId: ${reservation.id}");
      await ReservationApi().updateReservation(
        reservationId: reservation.id,
        isFixed: true,
      );
    } catch (e) {
      print('❌ 예약 확정 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약 확정 중 오류 발생')));
    }
    Navigator.pop(context);
    await loadData();
  }

  Future<void> _unfixReservation(
    BuildContext context,
    TableModel table,
    ReservationModel reservation,
  ) async {
    if (reservation.isFixed == false) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약 확정 취소 불가'),
          content: Text(
            '${table.tablename}번 테이블에 확정된 예약이 없습니다.\n먼저 예약 확정을 해주세요.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
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
            title: const Text('예약 확정 취소'),
            content: Text(
              '${table.tablename}번 테이블에 확정된 이 예약을 취소하시겠습니까?\n예약이 취소된 테이블은 이제 비딩을 받을 수 있습니다.',
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        '아니오',
                        style: TextStyle(color: Colors.white),
                      ),
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
                        '예',
                        style: TextStyle(color: Colors.black),
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
    showDialog(
      context: context,
      builder: (context) => CupertinoActivityIndicator(),
      barrierDismissible: false,
    );
    try {
      print("ReservationId: ${reservation.id}");
      await ReservationApi().updateReservation(
        reservationId: reservation.id,
        isFixed: false,
      );
    } catch (e) {
      print('❌ 예약 확정 취소 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약 확정 취소 중 오류 발생')));
    }
    Navigator.pop(context);
    await loadData();
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
                        side: BorderSide(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        '아니오',
                        style: TextStyle(color: Colors.white),
                      ),
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
                        style: TextStyle(color: Colors.black),
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
    showDialog(
      context: context,
      builder: (context) => CupertinoActivityIndicator(),
      barrierDismissible: false,
    );
    try {
      print("ReservationId: ${reservation.id}");
      await ReservationApi().reservationCheckIn(reservationId: reservation.id);
    } catch (e) {
      print('❌ ReservationCheckIn 입장 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('입장 처리 중 오류 발생')));
    }
    Navigator.pop(context);
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        '아니오',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '네',
                        style: TextStyle(color: Colors.black),
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
    showDialog(
      context: context,
      builder: (context) => CupertinoActivityIndicator(),
      barrierDismissible: false,
    );
    try {
      await ReservationApi().deleteReservation(reservationId: reservation.id);
    } catch (e) {
      print('❌ 예약 내역 삭제 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약 삭제 중 오류 발생')));
    }
    Navigator.pop(context);
    await loadData();
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
        title: Text('${widget.table.tablename} 예약'),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12,12,4,12),
            child: Tooltip(
              message: "예약 추가",
              child: IconButton(
                onPressed: () {
                  _showReservationAlert(context, widget.table);
                  },
                icon: Icon(Icons.add),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4,12,12,12),
            child: Tooltip(
              message: "새로 고침",
              child: IconButton(
                onPressed: () {
                  loadData();  
                },
                icon: Icon(Icons.refresh),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _reservations.isEmpty
          ? const Center(child: Text('예약 없음'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fixedReservation == null
                      ? SizedBox.shrink()
                      : FixedReservationTile(
                          reservation: fixedReservation,
                          onCheckIn: () => _admitReservation(
                            context,
                            widget.table,
                            fixedReservation,
                          ),
                          onCancel: () => _unfixReservation(
                            context,
                            widget.table,
                            fixedReservation,
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12,12,12,0),
                    child: _tableReserved ? 
                      ElevatedButton(
                      onPressed: () {},
                      child: Text('비딩 마감', style: TextStyle(fontSize: 12,)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
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
                    )
                    : ElevatedButton(
                      onPressed: () {},
                      child: Text('비딩 중', style: TextStyle(fontSize: 12,)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(229, 255, 153, 0),
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
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap:
                        true, // single~: 자식에게 무제한 높이 제공 -> Listview높이를 못 정해서 Render Error
                    padding: const EdgeInsets.all(12),
                    itemCount: leftBidList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final reservation = leftBidList[index];
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
                      return GestureDetector(
                        onTap: () => _showReservationModifyAlert(
                          context,
                          widget.table,
                          reservation.id,
                          reservation.reservationTime,
                          reservation.customerName,
                          reservation.customerPhone,
                          reservation.bidPrice,
                          // 이미 채워져 있는 값 보내기
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          title: Text(
                            '${reservation.customerName} ${reservation.reservationTime == null ? '' : DateFormat('HH:mm').format(reservation.reservationTime!)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${reservation.customerPhone}\n${formatPrice(reservation.bidPrice!)}',
                          ),
                          // subtitle: Text(
                          //   '${purchaseText} : ${formatPrice(resTotalPrice)}',
                          // ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: '입장',
                                onPressed: () => _fixReservation(
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
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
