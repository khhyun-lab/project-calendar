import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../stores/schedule_store.dart';

class CalendarSyncService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  // 1. 캘린더 접근 권한 확인 및 요청
  Future<bool> checkAndRequestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
      return true;
    }

    final requestResult = await _deviceCalendarPlugin.requestPermissions();
    return requestResult.isSuccess && (requestResult.data ?? false);
  }

  // 2. 기기에 등록된 캘린더 목록 조회 (Google, Apple, 로컬 등)
  Future<List<Calendar>> getDeviceCalendars() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      return [];
    }

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      return calendarsResult.data!;
    }

    return [];
  }

  // 3. 선택한 캘린더들로부터 특정 기간의 일정을 가져와 ScheduleStore에 등록
  Future<int> importEventsFromCalendars({
    required List<String> calendarIds,
    required DateTime startDate,
    required DateTime endDate,
    required ScheduleStore store,
    int colorIndex = 0,
  }) async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      return 0;
    }

    final importedSchedules = <Schedule>[];

    for (final calendarId in calendarIds) {
      final params = RetrieveEventsParams(
        startDate: startDate,
        endDate: endDate,
      );

      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendarId,
        params,
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        for (final event in eventsResult.data!) {
          if (event.start == null || event.end == null) continue;

          final DateTime startLocal = event.start!.toLocal();
          DateTime endLocal = event.end!.toLocal();

          // 종일 일정 처리
          if (event.allDay ?? false) {
            endLocal = DateTime(
              startLocal.year,
              startLocal.month,
              startLocal.day,
              23,
              59,
            );
          } else if (!endLocal.isAfter(startLocal)) {
            endLocal = startLocal.add(const Duration(hours: 1));
          }

          importedSchedules.add(
            Schedule(
              id: 'imported_${calendarId}_${event.eventId ?? UniqueKey().toString()}',
              title: event.title ?? '제목 없음',
              startTime: startLocal,
              endTime: endLocal,
              colorIndex: colorIndex,
              isShift: false,
            ),
          );
        }
      }
    }

    if (importedSchedules.isNotEmpty) {
      store.saveMultipleSchedules(importedSchedules);
    }

    return importedSchedules.length;
  }
}

