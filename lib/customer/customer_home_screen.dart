import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/customer/confirm_arrival_time.dart';
import 'package:tablebid/customer/customer_company_screen.dart';
import 'package:tablebid/customer/customer_setting_screen.dart';
import 'package:tablebid/customer/region_chip.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/reservation_api.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with WidgetsBindingObserver {
  static const _regions = ['강남', '이태원', '홍대', '신사/압구정', '기타'];
  List<CompanyModel> _companies = [];
  String _selectedRegion = _regions.first;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final companies = await CompanyApi().getCompanies();
      final fixedReservation = await ReservationApi().reservationUnder();
      if (fixedReservation != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConfirmArrivalTime(reservationId: fixedReservation.id),
          ),
          (route) => false,
        );
      }
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
  }

  Future<void> _openNaverMap(String address) async {
    final uri = Uri.https(
      'map.naver.com',
      '/p/search/${Uri.encodeComponent(address)}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('네이버 지도를 열 수 없습니다.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final visibleCompanies = _companies
        .where((company) => company.region == _selectedRegion)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('매장 선택'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CustomerSettingScreen(onUserChanged: null),
              ),
            ),
          ),
        ],
      ),
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
                        _loadInitialData();
                      },
                      child: const Text('매장 목록 다시 불러오기'),
                    ),
                  )
                : visibleCompanies.isEmpty
                ? const Center(
                    child: Text(
                      '해당 지역에 등록된 매장이 없습니다.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: visibleCompanies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final company = visibleCompanies[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerCompanyScreen(
                                company: company,
                                userId: user.uid,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ), // 배너 사이 간격
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(100),
                              borderRadius: BorderRadius.circular(
                                18,
                              ), // 🌟 아이폰 특유의 깊은 곡률
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상단 영역: 아이콘 + 앱 이름 + 시간
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Container(
                                    //   padding: const EdgeInsets.all(4),
                                    //   decoration: BoxDecoration(
                                    //     color: Colors.black,
                                    //     borderRadius: BorderRadius.circular(6),
                                    //   ),
                                    //   child: const Icon(
                                    //     Icons.grid_view_rounded,
                                    //     color: Colors.white,
                                    //     size: 12,
                                    //   ),
                                    // ),
                                  ],
                                ),
                                Text(
                                  company.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      company.address,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        height: 1.3,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _openNaverMap(company.address),
                                      icon: Icon(Icons.place),
                                    ),
                                  ],
                                ),
                              ],
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
