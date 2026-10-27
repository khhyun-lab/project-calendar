import 'package:flutter/material.dart';

enum CalendarThemeType {
  modernMinimal,
  softCard,
  deepNavy,
  warmCozy,
}

class CalendarThemeData {
  final CalendarThemeType type;
  final String name;
  final String description;
  final Color primaryColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final Color textColor;
  final Color weekendColor;
  final Color todayBorderColor;
  final BorderRadius cellRadius;
  final bool hasElevation;

  const CalendarThemeData({
    required this.type,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.surfaceColor,
    required this.backgroundColor,
    required this.textColor,
    required this.weekendColor,
    required this.todayBorderColor,
    required this.cellRadius,
    this.hasElevation = false,
  });

  static const List<CalendarThemeData> themes = [
    CalendarThemeData(
      type: CalendarThemeType.modernMinimal,
      name: '모던 미니멀',
      description: 'iOS 스타일의 깔끔하고 정돈된 블루 테마',
      primaryColor: Color(0xFF2563EB), // Blue 600
      surfaceColor: Color(0xFFF1F5F9), // Slate 100
      backgroundColor: Colors.white,
      textColor: Color(0xFF0F172A),
      weekendColor: Color(0xFFEF4444),
      todayBorderColor: Color(0xFF3B82F6),
      cellRadius: BorderRadius.all(Radius.circular(20)),
    ),
    CalendarThemeData(
      type: CalendarThemeType.softCard,
      name: '소프트 카드',
      description: '둥근 카드와 부드러운 인디고 컬러',
      primaryColor: Color(0xFF6366F1), // Indigo
      surfaceColor: Color(0xFFEEF2FF), // Indigo 50
      backgroundColor: Color(0xFFF8FAFC),
      textColor: Color(0xFF1E293B),
      weekendColor: Color(0xFFF43F5E),
      todayBorderColor: Color(0xFF6366F1),
      cellRadius: BorderRadius.all(Radius.circular(10)),
      hasElevation: true,
    ),
    CalendarThemeData(
      type: CalendarThemeType.deepNavy,
      name: '다크 시크',
      description: '고급스러운 딥 슬레이트 & 시안 포인트',
      primaryColor: Color(0xFF06B6D4), // Cyan 500
      surfaceColor: Color(0xFF1E293B), // Slate 800
      backgroundColor: Color(0xFF0F172A), // Slate 900
      textColor: Color(0xFFF8FAFC),
      weekendColor: Color(0xFFFB7185),
      todayBorderColor: Color(0xFF06B6D4),
      cellRadius: BorderRadius.all(Radius.circular(12)),
    ),
    CalendarThemeData(
      type: CalendarThemeType.warmCozy,
      name: '내추럴 웜',
      description: '따뜻한 오트밀과 올리브 감성 테마',
      primaryColor: Color(0xFF4D7C0F), // Olive Green
      surfaceColor: Color(0xFFFEF3C7), // Warm Amber 100
      backgroundColor: Color(0xFFFDFBF7), // Warm paper
      textColor: Color(0xFF451A03),
      weekendColor: Color(0xFFDC2626),
      todayBorderColor: Color(0xFF65A30D),
      cellRadius: BorderRadius.all(Radius.circular(14)),
    ),
  ];

  static CalendarThemeData getTheme(CalendarThemeType type) {
    return themes.firstWhere((t) => t.type == type, orElse: () => themes[0]);
  }
}

