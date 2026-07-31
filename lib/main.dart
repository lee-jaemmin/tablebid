import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/constants/sizes.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:tablebid/firebase_options.dart';
import 'dart:io';
import 'package:tablebid/screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("백그라운드 메시지 수신: ${message.messageId}");
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterAppBadger.removeBadge();

  kakao.KakaoSdk.init(
    nativeAppKey: 'f13eb4135ede439e8492dca27ef1d8fe',
  );
  await _initAsyncTasks();
  runApp(const tablebid());
}

Future<void> _initAsyncTasks() async {
  await FirebaseAppCheck.instance.activate(
    // 웹 환경이 아니라면 androidProvider에 Play Integrity를 설정합니다.
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  );

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // 2. 플러그인 초기화 실행
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      if (Platform.isAndroid && android != null) {
        // 안드로이드 수동 알림
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  });
}



class tablebid extends StatefulWidget {
  const tablebid({super.key});

  @override
  State<tablebid> createState() => _tablebidState();
}

class _tablebidState extends State<tablebid> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 감지기 부착
    FlutterAppBadger.removeBadge(); // 앱 껐다 켜질 때 배지 지우기
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 감지기 해제
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed) {
      FlutterAppBadger.removeBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'tablebid',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        primaryColor: Colors.white,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Sizes.size18,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: UnderlineInputBorder(),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          floatingLabelStyle: TextStyle(color: Colors.white),
        ),
        // 진행바 색
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.white,
        ),
        // BottomNavigationBar 색
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
