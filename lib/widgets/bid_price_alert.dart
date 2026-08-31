import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class BidPriceAlert extends StatefulWidget {
  final String companyId;
  final TableModel table;

  const BidPriceAlert({
    super.key,
    required this.companyId,
    required this.table,
  });

  @override
  State<BidPriceAlert> createState() => _BidPriceAlertState();
}

class _BidPriceAlertState extends State<BidPriceAlert> {
  late TextEditingController _priceController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _priceController.text = widget.table.leastBidPrice.toString();
  }

  @override
  void dispose() {
    _priceController.dispose();  
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text('${widget.table.tablename} 경매 최소가 변경')),
          ],
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
                      final leastBidPrice = int.parse(_priceController.text.replaceAll(',',''));
                      await TableApi().updateTable(tableId: widget.table.id, leastBidPrice: leastBidPrice);
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
