import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/schedule_color.dart';
import '../stores/schedule_store.dart';
import '../widgets/home_widget_views.dart';

class WidgetService {
  static const String appGroupId = 'group.com.today_schedule';
  static const String androidWidgetProvider4x2 = 'WidgetProvider4x2';
  static const String androidWidgetProvider4x4 = 'WidgetProvider4x4';
  static const String androidWidgetProvider4x6 = 'WidgetProvider4x6';

  static const String iOSWidgetKind = 'TodayScheduleWidget';

  // 1. 위젯 초기화
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      debugPrint('WidgetService: App Group ($appGroupId) initialized.');
    } catch (e) {
      debugPrint('WidgetService init error: $e');
    }
  }

  // 2. 4x2, 4x4, 4x6 세 종류의 모든 위젯 렌더링 및 네이티브 전송
  static Future<void> syncAllWidgets({
    required ScheduleStore store,
    TimeOfDay? customTime,
  }) async {
    final now = DateTime.now();
    final allSchedules = store.schedules;
    final time = customTime ?? TimeOfDay.now();

    try {
      // (1) 오늘 날짜 텍스트 & 현재 시간
      final hourStr = time.hour.toString().padLeft(2, '0');
      final minStr = time.minute.toString().padLeft(2, '0');
      final timeFormatted = '$hourStr:$minStr';
      final currentMinutes = time.hour * 60 + time.minute;

      final todaySchedules = store.getSchedulesForDay(now);

      await HomeWidget.saveWidgetData<String>('today_date_text', '${now.month}월 ${now.day}일');
      await HomeWidget.saveWidgetData<int>('today_schedule_count', todaySchedules.length);
      await HomeWidget.saveWidgetData<String>('current_time_text', timeFormatted);
      await HomeWidget.saveWidgetData<int>('current_time_minutes', currentMinutes);

      // (2) 오늘 일정 목록 (제목, 시작/종료 분, 색상, 당직여부)
      final todayList = todaySchedules.map((s) => {
        'title': s.title,
        'start': '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
        'end': '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
        'startMinutes': s.startTime.hour * 60 + s.startTime.minute,
        'endMinutes': s.endTime.hour * 60 + s.endTime.minute,
        'color': ScheduleColor.colors[s.colorIndex % ScheduleColor.colors.length].toARGB32(),
        'isShift': s.isShift,
      }).toList();
      await HomeWidget.saveWidgetData<String>('today_schedules_json', jsonEncode(todayList));

      // (3) 1달 캘린더 메타데이터 (년, 월, 총 일수, 1일 요일, 일정/당직 날짜 배열)
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7; // 일=0
      final scheduledDays = <int>{};
      final shiftDays = <int>{};
      for (final s in allSchedules) {
        if (s.startTime.year == now.year && s.startTime.month == now.month) {
          scheduledDays.add(s.startTime.day);
          if (s.isShift) shiftDays.add(s.startTime.day);
        }
      }

      final monthData = {
        'year': now.year,
        'month': now.month,
        'daysInMonth': daysInMonth,
        'firstWeekday': firstWeekday,
        'todayDay': now.day,
        'scheduledDays': scheduledDays.toList(),
        'shiftDays': shiftDays.toList(),
      };
      await HomeWidget.saveWidgetData<String>('month_calendar_json', jsonEncode(monthData));

      // (4) 4x2 위젯 이미지 렌더링 & 저장 (안드로이드 및 이미지 폴백용)
      final path4x2 = await HomeWidget.renderFlutterWidget(
        GlassAccessibilityScope(
          reduceMotion: false,
          reduceTransparency: false,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              color: const Color(0xFF0F172A),
              child: SizedBox(
                width: 360,
                height: 170,
                child: MonthWidgetView(
                  targetMonth: now,
                  schedules: allSchedules,
                  width: 360,
                  height: 170,
                ),
              ),
            ),
          ),
        ),
        key: 'filename_widget_4x2',
        logicalSize: const Size(360, 170),
      );
      if (path4x2 != null) {
        await HomeWidget.saveWidgetData<String>('filename_widget_4x2', path4x2);
      }

      // (5) 4x4 위젯 이미지 렌더링 & 저장
      final path4x4 = await HomeWidget.renderFlutterWidget(
        GlassAccessibilityScope(
          reduceMotion: false,
          reduceTransparency: false,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              color: const Color(0xFF0F172A),
              child: SizedBox(
                width: 360,
                height: 360,
                child: DayCircularWidgetView(
                  targetDay: now,
                  schedules: allSchedules,
                  displayTime: customTime,
                  width: 360,
                  height: 360,
                ),
              ),
            ),
          ),
        ),
        key: 'filename_widget_4x4',
        logicalSize: const Size(360, 360),
      );
      if (path4x4 != null) {
        await HomeWidget.saveWidgetData<String>('filename_widget_4x4', path4x4);
      }

      // (6) 4x6 위젯 이미지 렌더링 & 저장
      final path4x6 = await HomeWidget.renderFlutterWidget(
        GlassAccessibilityScope(
          reduceMotion: false,
          reduceTransparency: false,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              color: const Color(0xFF0F172A),
              child: SizedBox(
                width: 360,
                height: 540,
                child: CombinedWidgetView(
                  targetMonth: now,
                  targetDay: now,
                  schedules: allSchedules,
                  displayTime: customTime,
                  width: 360,
                  height: 540,
                ),
              ),
            ),
          ),
        ),
        key: 'filename_widget_4x6',
        logicalSize: const Size(360, 540),
      );
      if (path4x6 != null) {
        await HomeWidget.saveWidgetData<String>('filename_widget_4x6', path4x6);
      }

      // 네이티브 위젯 갱신 트리거 (iOS / Android)
      await HomeWidget.updateWidget(
        name: androidWidgetProvider4x2,
        iOSName: iOSWidgetKind,
      );
      await HomeWidget.updateWidget(
        name: androidWidgetProvider4x4,
        iOSName: iOSWidgetKind,
      );
      await HomeWidget.updateWidget(
        name: androidWidgetProvider4x6,
        iOSName: iOSWidgetKind,
      );

      debugPrint('HomeWidget: Synced metadata & images successfully.');
    } catch (e) {
      debugPrint('HomeWidget sync error: $e');
    }
  }
}
