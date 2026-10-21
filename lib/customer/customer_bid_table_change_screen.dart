import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/customer_company_screen.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/reservation_api.dart';

class CustomerBidTableChangeScreen extends StatefulWidget {
  final String companyId;
  final String currentTableId;
  final int reservationId;
  final String userId;

  const CustomerBidTableChangeScreen({
    super.key,
    required this.companyId,
    required this.currentTableId,
    required this.reservationId,
    required this.userId,
  });

  @override
  State<CustomerBidTableChangeScreen> createState() =>
      _CustomerBidTableChangeScreenState();
}

class _CustomerBidTableChangeScreenState
    extends State<CustomerBidTableChangeScreen> {
  late Future<CompanyModel> _companyFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _companyFuture = CompanyApi().getCompany(widget.companyId);
  }

  Future<void> _changeTable(TableModel table) async {
    if (_isSubmitting) return;
    if (table.id == widget.currentTableId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 입찰 중인 테이블입니다.')),
      );
      return;
    }
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보를 확인해주세요.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ReservationApi().updateReservation(
        reservationId: widget.reservationId,
        tableId: table.id,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테이블 변경 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CompanyModel>(
      future: _companyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _companyFuture = CompanyApi().getCompany(widget.companyId);
                }),
                child: const Text('회사 정보를 다시 불러오기'),
              ),
            ),
          );
        }
        return Stack(
          children: [
            CustomerCompanyScreen(
              company: snapshot.data!,
              userId: widget.userId,
              onTableSelected: _changeTable,
            ),
            if (_isSubmitting)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
