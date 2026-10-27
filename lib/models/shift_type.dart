import 'package:flutter/material.dart';

class ShiftType {
  final String id;
  final String name;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int colorIndex;
  final bool isOff;

  const ShiftType({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    required this.colorIndex,
    this.isOff = false,
  });

  bool get isNextDay {
    if (isOff || startTime == null || endTime == null) return false;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    return endMinutes <= startMinutes;
  }

  // 기본 시작 예시 (사용자가 모두 수정/삭제 가능)
  static List<ShiftType> get initialTypes => [
    const ShiftType(
      id: 'day',
      name: '주간',
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 18, minute: 0),
      colorIndex: 0,
    ),
    const ShiftType(
      id: 'night',
      name: '야간',
      startTime: TimeOfDay(hour: 18, minute: 0),
      endTime: TimeOfDay(hour: 9, minute: 0),
      colorIndex: 3,
    ),
    const ShiftType(
      id: 'duty',
      name: '당직',
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 9, minute: 0),
      colorIndex: 2,
    ),
    const ShiftType(
      id: 'off',
      name: 'OFF',
      colorIndex: 5,
      isOff: true,
    ),
  ];
}
