import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/customer_company_screen.dart';
import 'package:tablebid/customer/region_chip.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/services/company_api.dart';


class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _regions = ['강남', '이태원', '홍대', '신사/압구정'];
  List<CompanyModel> _companies = [];
  String _selectedRegion = _regions.first;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await CompanyApi().getCompanies();
      if (!mounted) return;
      setState(() {
        _companies = companies;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
    print(_companies.length);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final visibleCompanies = _companies
        .where((company) => company.region == _selectedRegion)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('매장 선택')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _regions.map((region) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: RegionChip(
                    region: region,
                    isSelected: region == _selectedRegion,
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: user == null
                ? const Center(child: Text('로그인이 필요합니다.'))
                : _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _hasError
                ? Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _hasError = false;
                        });
                        _loadCompanies();
                      },
                      child: const Text('매장 목록 다시 불러오기'),
                    ),
                  )
                : visibleCompanies.isEmpty
                ? const Center(child: Text('해당 지역에 등록된 매장이 없습니다.'))
                : RefreshIndicator(
                    onRefresh: _loadCompanies,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: visibleCompanies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final company = visibleCompanies[index];
                        return Card(
                          child: ListTile(
                            title: Text(company.name),
                            subtitle: Text(company.address),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerCompanyScreen(
                                  company: company,
                                  userId: user.uid,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}



