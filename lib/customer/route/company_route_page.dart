import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/customer_company_screen.dart';
import 'package:tablebid/customer/route/route_error_screen.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/services/company_api.dart';

class CustomerCompanyRoutePage extends StatefulWidget {
  final String companyId;

  const CustomerCompanyRoutePage({required this.companyId});

  @override
  State<CustomerCompanyRoutePage> createState() =>
      _CustomerCompanyRoutePageState();
}

class _CustomerCompanyRoutePageState extends State<CustomerCompanyRoutePage> {
  late Future<CompanyModel> _companyFuture;

  @override
  void initState() {
    super.initState();
    _companyFuture = CompanyApi().getCompany(widget.companyId);
  }

  void _retry() {
    setState(() {
      _companyFuture = CompanyApi().getCompany(widget.companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const RouteErrorScreen(message: '로그인이 필요합니다.');
    }
    return FutureBuilder<CompanyModel>(
      future: _companyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return RouteErrorScreen(
            message: '회사 정보를 불러오지 못했습니다.',
            onRetry: _retry,
          );
        }
        return CustomerCompanyScreen(company: snapshot.data!, userId: user.uid);
      },
    );
  }
}
