import 'package:go_router/go_router.dart';
import 'package:tablebid/customer/confirm_arrival_time.dart';
import 'package:tablebid/customer/route/bid_list_route_page.dart';
import 'package:tablebid/customer/route/company_route_page.dart';
import 'package:tablebid/customer/customer_home_screen.dart';
import 'package:tablebid/customer/route/route_names.dart';
import 'package:tablebid/customer/customer_setting_screen.dart';
import 'package:tablebid/customer/my_bids_screen.dart';
import 'package:tablebid/customer/route/route_error_screen.dart';
import 'package:tablebid/screens/login_screen.dart';
import 'package:tablebid/screens/splash_screen.dart';

/*
'/'가 있으면 최상위 루트 
없으면 그의 자식루트
*/

final GoRouter appRouter = GoRouter(
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
            companyId: state.pathParameters['companyId']!, // 여기도 ['abc']
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
  ],
);
