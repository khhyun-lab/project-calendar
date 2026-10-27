import 'package:flutter/foundation.dart';

import '../models/schedule.dart';
import '../services/widget_service.dart';

class ScheduleStore extends ChangeNotifier {
  final List<Schedule> _schedules = [];

  List<Schedule> get schedules => List.unmodifiable(_schedules);

  List<Schedule> getSchedulesForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day + 1);

    return _schedules.where((schedule) {
      return schedule.startTime.isBefore(dayEnd) &&
          schedule.endTime.isAfter(dayStart);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _triggerAutoSync() {
    WidgetService.syncAllWidgets(store: this).catchError((e) {
      debugPrint('ScheduleStore auto-sync error: $e');
    });
  }

  void saveSchedule(Schedule schedule) {
    final index = _schedules.indexWhere((item) => item.id == schedule.id);

    if (index == -1) {
      _schedules.add(schedule);
    } else {
      _schedules[index] = schedule;
    }

    notifyListeners();
    _triggerAutoSync();
  }

  void saveMultipleSchedules(List<Schedule> newSchedules) {
    for (final schedule in newSchedules) {
      final index = _schedules.indexWhere((item) => item.id == schedule.id);
      if (index == -1) {
        _schedules.add(schedule);
      } else {
        _schedules[index] = schedule;
      }
    }
    notifyListeners();
    _triggerAutoSync();
  }

  void deleteSchedule(String id) {
    _schedules.removeWhere((schedule) => schedule.id == id);
    notifyListeners();
    _triggerAutoSync();
  }

  // 특정 기간 내의 당직/교대 일정 일괄 삭제
  void clearShiftsInRange(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    _schedules.removeWhere((schedule) {
      if (!schedule.isShift) return false;
      return !schedule.startTime.isBefore(start) && !schedule.startTime.isAfter(end);
    });

    notifyListeners();
    _triggerAutoSync();
  }

  bool hasShiftsInRange(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _schedules.any((schedule) =>
        schedule.isShift &&
        !schedule.startTime.isBefore(start) &&
        !schedule.startTime.isAfter(end));
  }

  // 기존 호환용 메서드
  void clearShiftsForMonth(int year, int month) {
    final monthStart = DateTime(year, month, 1);
    final nextMonth = DateTime(year, month + 1, 1);
    final monthEnd = nextMonth.subtract(const Duration(days: 1));
    clearShiftsInRange(monthStart, monthEnd);
  }

  bool hasShiftsForMonth(int year, int month) {
    final monthStart = DateTime(year, month, 1);
    final nextMonth = DateTime(year, month + 1, 1);
    final monthEnd = nextMonth.subtract(const Duration(days: 1));
    return hasShiftsInRange(monthStart, monthEnd);
  }
}
