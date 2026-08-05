import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablebid/constants/gaps.dart';
import 'package:tablebid/methods/natural_sort.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/models/web_socket_event.dart';
import 'package:tablebid/screens/company_entry_screen.dart';
import 'package:tablebid/screens/history_screen.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/screens/menu_screen.dart';
import 'package:tablebid/screens/setting_screen.dart';
import 'package:tablebid/screens/staff_management_screen.dart';
import 'package:tablebid/screens/table_management_screen.dart';
import 'package:tablebid/screens/reservation_screen.dart';
import 'package:tablebid/services/company_api.dart';
import 'package:tablebid/services/table_api.dart';
import 'package:tablebid/services/user_api.dart';
import 'package:tablebid/services/websocket_service.dart';
import 'package:tablebid/widgets/notification_bell.dart';
import 'package:tablebid/widgets/sidebar_menu.dart';
import 'package:tablebid/widgets/table_gridview.dart';

/// FirebaseAuth.instance.currentUser로 UID 획득
/// -> Firestore에서 해당 UID 문서 조회
/// -> AppUser.fromMap으로 변환 -> UI에서 사용
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Map<String, TableModel> _tablesById = {};
  final Map<String, ValueNotifier<TableModel>> _tableNotifierById = {};
  Map<String, List<ValueNotifier<TableModel>>> _tableNotifierBySection = {};
  List<String> _sections = [];
  StreamSubscription<WebSocketEvent>? _webSocketEventSubscription;
  UserModel? _currentUser = null;
  CompanyModel? _company = null;
  bool _isLoading = true;
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
        return;
      }
      final user = await UserApi().getUser(currentUser.uid);
      final companyId = user.companyId?.trim();
      if (companyId == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyEntryScreen(userId: user.id),
          ),
          (route) => false,
        );
        return;
      }
      final result = await Future.wait([
        CompanyApi().getCompany(companyId),
        TableApi().getTables(companyId),
      ]);
      if (!mounted) return;
      final company = result[0] as CompanyModel;
      final tables = result[1] as List<TableModel>;
      setState(() {
        _setTables(tables);
        _company = company;
        _currentUser = user;
        _isLoading = false;
      });
      _subscribeToWebSocket(companyId);
    } catch (e) {
      print('이니셜 d 중 오류: $e');
      if (e.toString().contains('404') && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("이니셜 d 중 오류 발생")));
    }
  }

  void _subscribeToWebSocket(String companyId) {
    final service = WebsocketService.instance;
    _webSocketEventSubscription ??= service.events.listen(
      (event) {
        if (!mounted || event.type != 'table_updated') return;
        try {
          final updatedTable = TableModel.fromJson(event.payload);
          _applyTableUpdate(updatedTable);
        } catch (e) {
          print('테이블 실시간 업데이트 처리 실패: $e');
        }
      },
      onError: (error) {
        print('웹소켓 이벤트 처리 실패: $error');
      },
    );
    service.connect(companyId);
  }

  // 전체 조회 필요할 때 (테이블 수정, 삭제, 추가 등)
  void _setTables(List<TableModel> tables) {
    final newIds = tables.map((table) => table.id.toString()).toSet();
    final removedIds = _tablesById.keys
        .where((id) => !newIds.contains(id))
        .toList(); // Id들의 리스트

    // 삭제 테이블 정리
    for (final id in removedIds) {
      _tablesById.remove(id);
      final notifier = _tableNotifierById.remove(id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier?.dispose();
      });
    }

    // 새 테이블
    for (final table in tables) {
      final id = table.id;
      _tablesById[id] = table;

      final notifier = _tableNotifierById[id];
      if (notifier == null) {
        // table이 새로운 거면
        _tableNotifierById[id] = ValueNotifier<TableModel>(table);
      } else {
        // 있던 거면 값만 변경
        notifier.value = table;
      }
    }
    _rebuildSections();
  }

  void _rebuildSections() {
    final temporarySectionMap = <String, List<ValueNotifier<TableModel>>>{};

    for (final table in _tablesById.values) {
      final section = table.section.trim();
      if (section.isEmpty) continue;

      final notifier = _tableNotifierById[table.id];
      if (notifier == null) continue;

      temporarySectionMap.putIfAbsent(section, () => []).add(notifier);
    }

    final sortedSections = temporarySectionMap.keys.toList()
      ..sort((a, b) => naturalSortCompare(a, b));

    final sortedSectionMap = <String, List<ValueNotifier<TableModel>>>{};

    for (final section in sortedSections) {
      final notifiers = temporarySectionMap[section]!;
      notifiers.sort(
        (a, b) => naturalSortCompare(a.value.tablename, b.value.tablename),
      );
      sortedSectionMap[section] = notifiers;
    }

    _sections = sortedSections;
    _tableNotifierBySection = sortedSectionMap;
  }

  void _applyTableUpdate(TableModel updatedTable) {
    final id = updatedTable.id;
    final oldTable = _tablesById[id];
    final notifier = _tableNotifierById[id];

    final layoutChanged =
        oldTable == null ||
        oldTable.section != updatedTable.section ||
        oldTable.tablename != updatedTable.tablename;
    // 새 테이블이거나, 변경사항이 있으면 True

    if (notifier == null) {
      setState(() {
        _tablesById[id] = updatedTable;
        _tableNotifierById[id] = ValueNotifier<TableModel>(updatedTable);
        _rebuildSections();
      });
      return;
    }

    _tablesById[id] = updatedTable;
    notifier.value = updatedTable;

    if (layoutChanged) {
      setState(_rebuildSections);
    }
  }

  Future<void> _refreshHomeData() async {
    try {
      if (_company == null || _currentUser == null) {
        return;
      }
      final result = await Future.wait([
        CompanyApi().getCompany(_company!.id),
        TableApi().getTables(_company!.id),
      ]);
      if (!mounted) return;
      final company = result[0] as CompanyModel;
      final tables = result[1] as List<TableModel>;
      setState(() {
        _setTables(tables);
        _company = company;
        _refreshCount++;
      });

      await WebsocketService.instance.connect(_company!.id);
    } catch (e) {
      print('홈 새로고침 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새로고침 중 오류가 발생했습니다.')));
    }
  }

  Future<void> _syncTablesOnResume() async {
    // 화면 열면 바로 동기화하는 함수
    try {
      final company = _company;
      if (company == null) return;

      final tables = await TableApi().getTables(company.id);
      if (!mounted) return;
      setState(() {
        _setTables(tables);
        _refreshCount++;
      });

      await WebsocketService.instance.connect(company.id);
    } catch (e) {
      print('복귀 동기화 실패: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTablesOnResume();
    }
  }

  // scaffold key to open side bar safely
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // logout Function
  Future<void> signOutAndNavigate(BuildContext context) async {
    try {
      await WebsocketService.instance.disconnect();
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // 모든 이전 라우트를 제거 (false 반환)
        );
      }
    } catch (e) {
      print("로그아웃 오류: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _webSocketEventSubscription?.cancel();
    for (final notifier in _tableNotifierById.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CupertinoActivityIndicator(),
            ),
          ),
        ),
      );
    }
    final currentUser = _currentUser;
    final company = _company;

    if (currentUser == null) {
      return const LoginScreen();
    }

    if (company == null) {
      return CompanyEntryScreen(userId: currentUser.id);
    }

    final sections = _sections;

    return DefaultTabController(
      key: ValueKey(sections.length),
      length: sections.length,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: Drawer(
          backgroundColor: Color(0xFF2C2C2E),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 100.0),
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  final currentRole = currentUser.role;
                  return Column(
                    children: [
                      if (currentRole == 'owner') ...[
                        _buildInviteCodeCard(context),
                        Gaps.v20(context),
                      ],
                      if (currentRole == 'owner') ...[
                        SidebarMenu(
                          icon: Icons.person_3,
                          name: '직원 관리',
                          onTapFunc: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StaffmanagementScreen(
                                  companyId: company.id,
                                ),
                              ),
                            );
                          },
                        ),
                        Gaps.v20(context),
                      ],
                      if (currentRole == "owner" || currentRole == "admin") ...[
                        SidebarMenu(
                          icon: Icons.table_bar,
                          name: '테이블 배치 관리',
                          onTapFunc: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TableManagementScreen(
                                  companyId: company.id,
                                  userId: currentUser.id,
                                ),
                              ),
                            );
                          },
                        ),
                        Gaps.v20(context),
                        SidebarMenu(
                          icon: Icons.restaurant_menu,
                          name: '메뉴 관리',
                          onTapFunc: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MenuScreen(companyId: company.id),
                              ),
                            );
                          },
                        ),
                        Gaps.v20(context),
                      ],
                      SidebarMenu(
                        icon: Icons.alarm,
                        name: '예약',
                        onTapFunc: () async {
                          Navigator.pop(context);
                          if (!context.mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationScreen(
                                companyId: company.id,
                                userId: currentUser.id,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          await _syncTablesOnResume();
                        },
                      ),
                      Gaps.v20(context),
                      SidebarMenu(
                        icon: Icons.rotate_left,
                        name: '히스토리',
                        onTapFunc: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryScreen(
                                companyId: currentUser.companyId!,
                              ),
                            ),
                          );
                        },
                      ),
                      Gaps.v20(context),
                      SidebarMenu(
                        icon: Icons.settings,
                        name: '설정',
                        onTapFunc: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SettingScreen(initialUser: currentUser),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        appBar: AppBar(
          title: Text(company.name),
          actions: [
            NotificationBell(user: currentUser, companyId: company.id),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                child: const Icon(Icons.menu),
              ),
            ),
          ],
          bottom: sections.isEmpty
              ? null
              : TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 4,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontSize: 16),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                  tabAlignment: TabAlignment.start,
                  isScrollable: true,
                  tabs: sections.map((s) => Tab(text: s)).toList(),
                ),
        ),
        body: sections.isEmpty
            ? RefreshIndicator(
                onRefresh: _refreshHomeData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 500,
                      child: Center(
                        child: Text('설정된 섹션이 없습니다. 관리자 모드에서 추가해주세요.'),
                      ),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: sections.map((section) {
                  return RefreshIndicator(
                    onRefresh: _refreshHomeData,
                    child: TableGridView(
                      key: ValueKey('$section-$_refreshCount'),
                      companyId: company.id,
                      tableNotifiers:
                          _tableNotifierBySection[section] ?? const [],
                      visibleFields: currentUser.cardfields,
                      userId: currentUser.id,
                      userName: currentUser.userName,
                      physics: const AlwaysScrollableScrollPhysics(),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildInviteCodeCard(BuildContext context) {
    final company = _company;
    if (company == null) {
      return LoginScreen();
    }
    String inviteCode = company.inviteCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '매장 초대 코드',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  _company!.inviteCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 30),
            Expanded(
              child: IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.black87),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('초대 코드가 복사되었습니다.')),
                  );
                },
              ),
            ),
            Expanded(
              child: IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh, size: 20, color: Colors.black),
                onPressed: () => _showReissueDialog(context, company.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 초대 코드 재발급
  void _showReissueDialog(BuildContext context, String companyId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('초대 코드 재발급'),
        content: const Text('코드를 재발급하면 기존 코드는 더 이상 사용할 수 없습니다.\n정말 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10),
              ),
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ontext) =>
                    const Center(child: CircularProgressIndicator()),
              );
              // DB 업데이트
              try {
                await CompanyApi().regenerateInviteCode(companyId: companyId);
                navigator.pop(); // 로딩창 끄기
                navigator.pop(); // 재발급하시겠습니까? 팝업 끄기
                setState(() {
                  _buildInviteCodeCard(context);
                });
              } catch (e) {
                navigator.pop(); // 로딩창 끄기
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('코드 재발급에 실패했습니다. 다시 시도해주세요'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                print("재발급 실패: $e");
              }
            },
            child: const Text(
              '재발급 실행',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
