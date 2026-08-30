import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tablebid/models/log_model.dart';
import 'package:tablebid/services/log_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class EditPurchaseScreen extends StatefulWidget {
  final tableId;
  const EditPurchaseScreen({required this.tableId, super.key});

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  List<LogModel> _logs = [];
  bool _isLoading = true;

  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await LogApi().getLogs(widget.tableId);

    if (!context.mounted) return;

    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _modifyLogsAndPurchases(LogModel log) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('구매 취소 확인'),
          content: Text('${log.itemName} ${log.quantity}개 구매 기록을 취소하시겠습니까?'),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text('아니오'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text('네', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // 밖에 누르면 null이 올 수도 있음. true로 체크

    print(
      'delete log id=${log.id}, itemId=${log.itemId}, name=${log.itemName}, 개수=${log.quantity}',
    );
    showDialog(
      context: context,
      builder: (context) => const CupertinoActivityIndicator(),
      barrierDismissible: false,
    );
    try {
      await LogApi().deleteLogAndPurchase(logId: log.id);
      if (!context.mounted) return;
      await _loadData();
      Navigator.pop(context);
    } catch (e) {
      print(e);
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구매 내역 삭제 도중 오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('구매 내역 관리')),
      body: _isLoading
          ? Center(child: const CupertinoActivityIndicator())
          : _logs.length == 0
          ? Center(child: Text('아직 구매 내역이 없습니다.'))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isNewBatch = index == 0 || _logs[index - 1].batchId != log.batchId;
                return Column(
                  children: [
                    isNewBatch ? Divider() : SizedBox.shrink(),
                    ListTile(
                      isThreeLine: true,
                      title: Text(log.itemName),
                      subtitle: Text('수량: ${log.quantity}\n${DateFormat("MM/dd HH:mm").format(log.createdAt)}'),
                      trailing: Text(
                        formatPrice(log.quantity * log.unitPrice),
                        style: TextStyle(fontSize: 16),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          onPressed: () async {
                            _modifyLogsAndPurchases(log);
                          },
                          icon: Icon(Icons.delete_rounded),
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
