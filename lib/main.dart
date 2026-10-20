import 'package:flutter/material.dart';

import 'screens/main_screen.dart';

void main() {
  runApp(const TodayScheduleApp());
}

class TodayScheduleApp extends StatelessWidget {
  const TodayScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오늘의 스케쥴',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainScreen(),
    );
  }
}
