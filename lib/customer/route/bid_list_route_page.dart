import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/customer_bid_list_screen.dart';
import 'package:tablebid/customer/route/route_error_screen.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/table_api.dart';

class CustomerBidListRoutePage extends StatefulWidget {
  final String companyId;
  final String tableId;

  const CustomerBidListRoutePage({
    required this.companyId,
    required this.tableId,
  });

  @override
  State<CustomerBidListRoutePage> createState() =>
      _CustomerBidListRoutePageState();
}

class _CustomerBidListRoutePageState extends State<CustomerBidListRoutePage> {
  late Future<TableModel> _tableFuture;

  @override
  void initState() {
    super.initState();
    _tableFuture = TableApi().getTable(widget.tableId);
  }

  void _retry() {
    setState(() {
      _tableFuture = TableApi().getTable(widget.tableId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const RouteErrorScreen(message: '로그인이 필요합니다.');
    }
    return FutureBuilder<TableModel>(
      future: _tableFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CupertinoActivityIndicator()),
          );
        }
        final table = snapshot.data;
        if (snapshot.hasError ||
            table == null ||
            table.companyId != widget.companyId) {
          return RouteErrorScreen(
            message: '테이블 정보를 불러오지 못했습니다.',
            onRetry: _retry,
          );
        }
        return CustomerBidListScreen(
          companyId: widget.companyId,
          table: table,
          userId: user.uid,
        );
      },
    );
  }
}
