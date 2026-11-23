import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:tablebid/customer/confirm_arrival_time.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/models/user_model.dart';
import 'package:tablebid/route/bid_list_route_page.dart';
import 'package:tablebid/route/company_route_page.dart';
import 'package:tablebid/customer/customer_home_screen.dart';
import 'package:tablebid/route/route_names.dart';
import 'package:tablebid/customer/customer_setting_screen.dart';
import 'package:tablebid/customer/my_bids_screen.dart';
import 'package:tablebid/route/route_error_screen.dart';
import 'package:tablebid/screens/history_screen.dart';
import 'package:tablebid/screens/home_screen.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/screens/menu_screen.dart';
import 'package:tablebid/screens/move_screen.dart';
import 'package:tablebid/screens/notification_screen.dart';
import 'package:tablebid/screens/reservation_list_screen.dart';
import 'package:tablebid/screens/reservation_screen.dart';
import 'package:tablebid/screens/setting_screen.dart';
import 'package:tablebid/screens/splash_screen.dart';
import 'package:tablebid/screens/staff_management_screen.dart';
import 'package:tablebid/screens/table_management_screen.dart';
import 'package:tablebid/services/user_api.dart';

/*
'/'가 있으면 최상위 루트 
없으면 그의 자식루트
*/

UserModel? _workerUser;

final GoRouter appRouter = GoRouter(
  redirect: (context, state) async {
    final path = state.uri.path;
    if (path != '/worker' && !path.startsWith('/worker/')) {
      return null;
    } // 직원 화면 아니면 검사진행 x

    final firebaseUser = await FirebaseAuth.instance
        .authStateChanges()
        .first; // currentUser: 그 즉시 값을 읽음. 얘는 로그인 상태가 복원되기를 기다려줌
    if (firebaseUser == null) {
      _workerUser = null;
      return '/signup';
    }

    try {
      final user = await UserApi().getUser(firebaseUser.uid);
      if (user.role == null ||
          user.role == 'customer' ||
          (user.companyId ?? '').trim().isEmpty) {
        _workerUser = null;
        return '/customer';
      }
      if (state.uri.path == '/worker/moveScreen' && state.extra is !TableModel) {
        return '/worker';
      }
      _workerUser = user;
      return null;
    } catch (_) {
      _workerUser = null;
      rethrow;
    }
  },
  routes: [
    GoRoute(
      path: '/',
      name: rootRouteName,
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: customerSignUpRouteName,
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/customer',
      name: customerHomeRouteName,
      builder: (context, state) => const CustomerHomeScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          name: customerSettingsRouteName,
          builder: (context, state) =>
              const CustomerSettingScreen(onUserChanged: null),
        ),
        GoRoute(
          path: 'bids',
          name: customerMyBidsRouteName,
          builder: (context, state) => const MyBidsScreen(),
        ),
        GoRoute(
          path: 'arrival/:reservationId',
          name: customerArrivalRouteName,
          builder: (context, state) {
            final reservationId = int.tryParse(
              state.pathParameters['reservationId'] ?? '',
            );
            if (reservationId == null) {
              return const RouteErrorScreen(message: '잘못된 예약 주소입니다.');
            }
            return ConfirmArrivalTime(reservationId: reservationId);
          },
        ),
        GoRoute(
          // 'companies/: abc'이면
          path: 'companies/:companyId',
          name: customerCompanyRouteName,
          builder: (context, state) => CustomerCompanyRoutePage(
            companyId: state.pathParameters['companyId']!, // 여기도 ['abc']마지
          ),
          routes: [
            // 자식 라우트
            GoRoute(
              path: 'tables/:tableId/bids',
              name: customerBidListRouteName,
              builder: (context, state) => CustomerBidListRoutePage(
                companyId: state.pathParameters['companyId']!,
                tableId: state.pathParameters['tableId']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/worker',
      name: 'workerHome',
      builder: (context, state) => HomeScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          name: 'workerSettings',
          builder: (context, state) => SettingScreen(initialUser: _workerUser!),
        ),
        GoRoute(
          path: 'bidTables',
          name: 'workerBidTables',
          builder: (context, state) => ReservationScreen(
            companyId: _workerUser!.companyId!,
            userId: _workerUser!.id,
          ),
          routes: [
            GoRoute(
              path: ':tableId/bids',
              name: 'workerBidLists',
              builder: (context, state) {
                final tableId = state.pathParameters['tableId']!;
                return ReservationListScreen(
                  companyId: _workerUser!.companyId!,
                  tableId: tableId,
                  userId: _workerUser!.id,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'tableSettings',
          name: 'workerTableSettings',
          builder: (context, state) => TableManagementScreen(
            companyId: _workerUser!.companyId!,
            userId: _workerUser!.id,
          ),
        ),
        GoRoute(
          path: 'staffManagement',
          name: 'staffMangement',
          builder: (context, state) {
            return StaffmanagementScreen(companyId: _workerUser!.companyId!);
          },
        ),
        GoRoute(
          // 'companies/: abc'이면
          path: 'histories',
          name: 'histories',
          builder: (context, state) =>
              HistoryScreen(companyId: _workerUser!.companyId!),
        ),
        GoRoute(
          path: 'menuManagement',
          name: 'menuManagement',
          builder: (context, state) =>
              MenuScreen(companyId: _workerUser!.companyId!),
        ),
        GoRoute(
          path: 'workerNotification',
          name: 'workerNotification',
          builder: (context, state) =>
              NotificationHistoryScreen(companyId: _workerUser!.companyId!),
        ),
        GoRoute(
          path: 'moveScreen',
          name: 'moveScreen',
          builder: (context, state) =>
              MoveScreen(companyId: _workerUser!.companyId!, fromTable: state.extra as TableModel, userId: _workerUser!.id),
        ),
      ],
    ),
  ],
);
