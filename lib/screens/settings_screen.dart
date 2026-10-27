import 'package:flutter/material.dart';

import '../stores/schedule_store.dart';
import '../widgets/calendar_import_sheet.dart';
import 'widget_preview_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ScheduleStore store;

  const SettingsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          // 캘린더 동기화 섹션 (요구사항 7)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '캘린더 동기화',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007AFF)),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sync_alt, color: Color(0xFF007AFF)),
            ),
            title: const Text('기기 캘린더에서 일정 가져오기', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Google, Apple 캘린더 및 공휴일 일정을 불러옵니다.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              CalendarImportSheet.show(context, store);
            },
          ),
          const Divider(),

          // 홈 화면 위젯 섹션 (요구사항 2, 3, 4, 5)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '홈 화면 위젯',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007AFF)),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.widgets_outlined, color: Colors.purple),
            ),
            title: const Text('홈 화면 위젯 설정 (4x2, 4x4, 4x6)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('1달 달력, 24시간 원형 일정, 결합형 위젯 미리보기 및 동기화'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WidgetPreviewScreen(store: store)),
              );
            },
          ),
          const Divider(),

          // 계정 및 SSO 섹션 (요구사항 6)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '계정 연동 (SSO)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.g_mobiledata, size: 28),
            title: const Text('구글 계정으로 로그인'),
            subtitle: const Text('Google ID SSO 로그인 준비 중'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('구글 로그인 기능 연결 예정입니다.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.apple, size: 28),
            title: const Text('Apple로 로그인'),
            subtitle: const Text('Apple ID SSO 로그인 준비 중'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('애플 로그인 기능 연결 예정입니다.')),
              );
            },
          ),
          const Divider(),

          // 앱 정보
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '앱 정보',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 이름'),
            subtitle: Text('All-in-One Schedule (올인원 스케줄)'),
          ),
          const ListTile(
            leading: Icon(Icons.verified_outlined),
            title: Text('버전'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
