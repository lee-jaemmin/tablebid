import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class BidPriceAlert extends StatefulWidget {
  final String companyId;
  final TableModel table;
  final String userId;
  final ValueChanged<TableModel> onTableChanged;

  const BidPriceAlert({
    super.key,
    required this.companyId,
    required this.table,
    required this.userId,
    required this.onTableChanged,
  });

  @override
  State<BidPriceAlert> createState() => _BidPriceAlertState();
}

class _BidPriceAlertState extends State<BidPriceAlert> {
  late TextEditingController _priceController;
  late TextEditingController _offerProductsController;
  late TextEditingController _bidEndAtController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _priceController.text = widget.table.leastBidPrice == null
        ? ""
        : formatPrice(widget.table.leastBidPrice!);
    _offerProductsController = TextEditingController();
    _offerProductsController.text = widget.table.offerProducts ?? "";
    _bidEndAtController = TextEditingController();
    _bidEndAtController.text = widget.table.bidEndAt == null
        ? ""
        : DateFormat("MM-dd HH:mm").format(widget.table.bidEndAt!);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _offerProductsController.dispose();
    _bidEndAtController.dispose();
    super.dispose();
  }

  Future<void> _showCupertinoTimerPicker(BuildContext context) async {
    if (widget.table.bidAvailable == false) {
      if (mounted) Navigator.pop(context); // info_alert 내리기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 테이블은 경매가 비활성화 되어있습니다. 경매 기능을 먼저 켜주세요'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    DateTime? selectedDateTime = null;

    // await => 빈 공간을 터치해 팝업을 닫을 때까지 기다림
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 500, // 상단바가 빠졌으니 높이를 살짝 줄임
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time, // mm:ss
              initialDateTime: DateTime.now(),
              onDateTimeChanged: (DateTime newDateTime) {
                selectedDateTime = newDateTime;
              },
            ),
          ),
        );
      },
    );

    // 팝업이 닫히면 서버로 전송
    if (selectedDateTime != null) {
      if (selectedDateTime!.isBefore(DateTime.now())) {
        selectedDateTime = selectedDateTime!.add(Duration(days: 1));
      } // 지금보다 늦은 오전 선택 시
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CupertinoActivityIndicator()),
      );
      try {
        final table = await TableApi().updateTable(
          tableId: widget.table.id,
          userId: widget.userId,
          bidEndAt: selectedDateTime,
        );
        widget.onTableChanged(table);
      } catch (e) {
        print(e);
      }
      // 타이머 db로 보내기

      navigator.pop(); // 로딩창 끄기
      navigator.pop(); // info 내리기
      messenger.showSnackBar(
        SnackBar(
          content: Text("비딩 마감 시간이 변경되었습니다."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('${widget.table.tablename} 경매 설정 변경')],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '비딩 최소가 (단위: 원)'),
                  inputFormatters: [PriceFormatters()],
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _offerProductsController,
                  decoration: InputDecoration(labelText: '제공 품목'),
                  minLines: null,
                  maxLines: null,
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showCupertinoTimerPicker(context),
                  child: InputDecorator(
                    child: Text(
                      _bidEndAtController.text,
                      style: TextStyle(fontSize: 16),
                    ),
                    decoration: InputDecoration(labelText: '비딩 마감 시간'),
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(color: Colors.white),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    '취소',
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
                  onPressed: () async {
                    setState(() {
                      _isSubmitting = true;
                    });
                    try {
                      final leastBidPrice = int.parse(
                        _priceController.text
                            .replaceAll(',', '')
                            .replaceAll('원', ''),
                      );
                      await TableApi().updateTable(
                        tableId: widget.table.id,
                        leastBidPrice: leastBidPrice,
                        offerProducts: _offerProductsController.text,
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      print('❌ 최소가 변경 중 에러 발생: $e');
                      Navigator.pop(context);
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('최소가 변경 중 에러 발생')));
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CupertinoActivityIndicator(
                            color: Colors.black,
                          ),
                        )
                      : const Text('등록', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
