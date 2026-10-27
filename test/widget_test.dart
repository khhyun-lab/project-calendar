import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:today_schedule/main.dart';

void main() {
  testWidgets('오늘의 스케쥴 앱 실행 테스트', (tester) async {
    // 앱 실행
    await tester.pumpWidget(const TodayScheduleApp());

    // 앱 제목이 표시되는지 확인
    expect(find.text('All-in-One Schedule'), findsOneWidget);

    // 하단 메뉴가 표시되는지 확인
    expect(find.text('캘린더'), findsOneWidget);
    expect(find.text('하루'), findsOneWidget);
    expect(find.text('근무표'), findsOneWidget);

    // 설정 버튼이 있는지 확인
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
