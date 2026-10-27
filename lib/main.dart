import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.initialize();
  runApp(const TodayScheduleApp());
}

class TodayScheduleApp extends StatelessWidget {
  const TodayScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'All-in-One Schedule',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainScreen(),
    );
  }
}
