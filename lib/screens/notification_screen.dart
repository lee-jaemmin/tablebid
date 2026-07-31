import 'package:flutter/material.dart';
import 'package:tablebid/models/notification_model.dart';
import 'package:tablebid/services/notification_api.dart';

class NotificationHistoryScreen extends StatelessWidget {
  final String companyId;

  const NotificationHistoryScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '알림 센터',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0, // AppBar 경계선 제거로 더 깔끔하게
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: NotificationApi().getNotifications(companyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '알림을 가져오는 중 오류 발생: ${snapshot.error}}',
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final title = notification.title;
              final body = notification.body;
              final DateTime? timestamp = notification.createdAt;

              String dateTimeString = ''; // 날짜+시간을 담을 변수

              if (timestamp != null) {
                final time = timestamp.toLocal();

                // 날짜 포맷 (예: 03/24)
                final String month = time.month.toString().padLeft(2, '0');
                final String day = time.day.toString().padLeft(2, '0');

                // 요일 계산
                const weekdayList = ['월', '화', '수', '목', '금', '토', '일'];
                final String weekday = weekdayList[time.weekday - 1];

                // 시간 포맷 (예: 01:23)
                final String hour = time.hour.toString().padLeft(2, '0');
                final String minute = time.minute.toString().padLeft(2, '0');

                // 최종 결과물: 03/24(화) 01:23
                dateTimeString = '$month/$day($weekday) $hour:$minute';
              }

              // iOS Notification Banner Style Container
              return Container(
                margin: const EdgeInsets.only(bottom: 12), // 배너 사이 간격
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18), // 🌟 아이폰 특유의 깊은 곡률
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GRID', // 앱 이름
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          dateTimeString,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 하단 영역: 제목 + 본문
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
