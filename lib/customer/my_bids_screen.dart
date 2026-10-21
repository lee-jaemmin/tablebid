import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tablebid/customer/route/route_names.dart';
import 'package:tablebid/models/my_bid_model.dart';
import 'package:tablebid/services/my_bid_api.dart';
import 'package:tablebid/widgets/price_formatter.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  List<MyBidModel> _bids = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final bids = await MyBidApi().getMyBids();
      if (!mounted) return;
      setState(() {
        _bids = bids;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입찰 내역을 불러오지 못했습니다.')));
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('도움말'),
        content: const Text('내가 입찰한 회사, 테이블과 입찰 가격을 확인할 수 있습니다.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 입찰 보기'),
        actions: [
          IconButton(
            tooltip: '도움말',
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: '새로고침',
            onPressed: _isLoading ? null : _loadBids,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _hasError
          ? Center(
              child: ElevatedButton(
                onPressed: _loadBids,
                child: const Text('다시 시도'),
              ),
            )
          : _bids.isEmpty
          ? const Center(child: Text('입찰 내역이 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _bids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bid = _bids[index];
                final price = bid.bidPrice == null
                    ? '-'
                    : formatPrice(bid.bidPrice!);
                return Card(
                  child: ListTile(
                    onTap: () => context.pushNamed(
                      customerBidListRouteName,
                      pathParameters: {
                        'companyId': bid.companyId,
                        'tableId': bid.tableId,
                      },
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    title: Text(
                      bid.companyName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('${bid.tableName}\n$price'),
                    trailing: bid.isFixed
                        ? ElevatedButton(
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
                                borderRadius: BorderRadiusGeometry.circular(8),
                              ),
                            ),
                            child: const Text(
                              '확정된 예약',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: bid.rank == 1
                                ? FaIcon(
                                    FontAwesomeIcons.medal,
                                    color: const Color.fromARGB(
                                      255,
                                      240,
                                      198,
                                      71,
                                    ),
                                  )
                                : bid.rank == 2
                                ? FaIcon(
                                    FontAwesomeIcons.medal,
                                    color: const Color.fromARGB(
                                      251,
                                      163,
                                      161,
                                      161,
                                    ),
                                  )
                                : bid.rank == 3
                                ? FaIcon(
                                    FontAwesomeIcons.medal,
                                    color: Colors.brown,
                                  )
                                : Text(
                                    '내 순위: ${bid.rank.toString()}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
