import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/schedule.dart';
import '../models/schedule_color.dart';

// =============================================================================
// 1. 4x2 위젯: 1달치 캘린더 (liquid_glass_widgets + Deep Obsidian Glass Base)
// =============================================================================
class MonthWidgetView extends StatelessWidget {
  final DateTime targetMonth;
  final List<Schedule> schedules;
  final double? width;
  final double? height;

  const MonthWidgetView({
    super.key,
    required this.targetMonth,
    required this.schedules,
    this.width = 360,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    final year = targetMonth.year;
    final month = targetMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 일=0

    final now = DateTime.now();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B), // Deep Frosted Obsidian Glass Base
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: GlassContainer(
        useOwnLayer: true,
        width: width,
        height: height,
        settings: LiquidGlassSettings.ios27Dark,
        shape: const LiquidRoundedSuperellipse(borderRadius: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFF0F172A).withValues(alpha: 0.3),
        glowIntensity: 0.25,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 년/월 및 오늘 날짜 캡슐
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$month월',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                // 오늘 날짜 리퀴드 글래스 캡슐
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF64D2FF).withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '오늘 ${now.month}.${now.day}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64D2FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 요일 바 (선명한 SF Pro 스타일 폰트)
            Row(
              children: const [
                Expanded(child: Center(child: Text('일', style: TextStyle(color: Color(0xFFFF5252), fontSize: 10, fontWeight: FontWeight.w800)))),
                Expanded(child: Center(child: Text('월', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)))),
                Expanded(child: Center(child: Text('화', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)))),
                Expanded(child: Center(child: Text('수', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)))),
                Expanded(child: Center(child: Text('목', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)))),
                Expanded(child: Center(child: Text('금', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)))),
                Expanded(child: Center(child: Text('토', style: TextStyle(color: Color(0xFF40C4FF), fontSize: 10, fontWeight: FontWeight.w800)))),
              ],
            ),
            const SizedBox(height: 3),

            // 1달 달력 그리드 (크고 선명한 날짜 숫자 및 일정 도트)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (week) {
                  return Expanded(
                    child: Row(
                      children: List.generate(7, (dayOfWeek) {
                        final idx = week * 7 + dayOfWeek;
                        final dayNumber = idx - firstWeekday + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const Expanded(child: SizedBox.shrink());
                        }

                        final currentDate = DateTime(year, month, dayNumber);
                        final daySchedules = schedules.where((s) {
                          return s.startTime.year == year &&
                              s.startTime.month == month &&
                              s.startTime.day == dayNumber;
                        }).toList();

                        final isToday = DateUtils.isSameDay(currentDate, now);
                        final isSunday = dayOfWeek == 0;
                        final isSaturday = dayOfWeek == 6;

                        Color dayTextColor = Colors.white.withValues(alpha: 0.95);
                        if (isSunday) dayTextColor = const Color(0xFFFF6B6B);
                        if (isSaturday) dayTextColor = const Color(0xFF69D2FF);

                        return Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 15,
                                  alignment: Alignment.center,
                                  decoration: isToday
                                      ? BoxDecoration(
                                          color: const Color(0xFFFF3B30),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        )
                                      : null,
                                  child: Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                                      color: isToday ? Colors.white : dayTextColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 3.5,
                                  height: 3.5,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: daySchedules.isNotEmpty
                                        ? ScheduleColor.colors[daySchedules.first.colorIndex % ScheduleColor.colors.length]
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. 4x4 위젯: 24시간 원형 일정 (liquid_glass_widgets + Deep Obsidian Glass Base)
// =============================================================================
class DayCircularWidgetView extends StatelessWidget {
  final DateTime targetDay;
  final List<Schedule> schedules;
  final TimeOfDay? displayTime;
  final double? width;
  final double? height;

  const DayCircularWidgetView({
    super.key,
    required this.targetDay,
    required this.schedules,
    this.displayTime,
    this.width = 360,
    this.height = 360,
  });

  @override
  Widget build(BuildContext context) {
    final rangeStart = DateTime(targetDay.year, targetDay.month, targetDay.day);
    final rangeEnd = DateTime(targetDay.year, targetDay.month, targetDay.day + 1);

    final daySchedules = schedules.where((s) {
      return s.startTime.isBefore(rangeEnd) && s.endTime.isAfter(rangeStart);
    }).toList();

    final time = displayTime ?? TimeOfDay.now();

    // 현재 진행 중이거나 가장 가까운 다음 일정 찾기
    final nowMinutes = time.hour * 60 + time.minute;
    Schedule? currentOrNextSchedule;
    for (final s in daySchedules) {
      final sStart = s.startTime.hour * 60 + s.startTime.minute;
      final sEnd = s.endTime.hour * 60 + s.endTime.minute;
      if (nowMinutes >= sStart && nowMinutes <= sEnd) {
        currentOrNextSchedule = s;
        break;
      }
    }
    if (currentOrNextSchedule == null && daySchedules.isNotEmpty) {
      currentOrNextSchedule = daySchedules.first;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B), // Deep Frosted Obsidian Glass Base
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: GlassContainer(
        useOwnLayer: true,
        width: width,
        height: height,
        settings: LiquidGlassSettings.ios27Dark,
        shape: const LiquidRoundedSuperellipse(borderRadius: 28),
        padding: const EdgeInsets.all(14),
        color: const Color(0xFF0F172A).withValues(alpha: 0.3),
        glowIntensity: 0.25,
        child: Column(
          children: [
            // 상단 간결 헤더 (날짜 및 일정 개수만 표시)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${targetDay.month}월 ${targetDay.day}일 (${_weekdayKorean(targetDay.weekday)})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '일정 ${daySchedules.length}건',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64D2FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // 중앙: 화면 86%를 채우는 초대형 24시간 원형 시계 차트
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _LargeLiquidCirclePainter(
                      schedules: daySchedules,
                      displayTime: time,
                      targetDay: targetDay,
                      currentSchedule: currentOrNextSchedule,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayKorean(int weekday) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[(weekday - 1) % 7];
  }
}

// =============================================================================
// 3. 초대형 리퀴드 글래스 24시간 원형 일정 페인터
// =============================================================================
class _LargeLiquidCirclePainter extends CustomPainter {
  final List<Schedule> schedules;
  final TimeOfDay displayTime;
  final DateTime targetDay;
  final Schedule? currentSchedule;

  _LargeLiquidCirclePainter({
    required this.schedules,
    required this.displayTime,
    required this.targetDay,
    this.currentSchedule,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 원 크기를 영역의 84%까지 극대화
    final outerRadius = size.width * 0.42;
    final strokeWidth = size.width * 0.085;

    final dayStart = DateTime(targetDay.year, targetDay.month, targetDay.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // 1. 24시간 베이스 글래스 트랙
    final baseTrackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius, baseTrackPaint);

    // 2. 24시간 주요 마커 링 눈금 및 텍스트 (00, 06, 12, 18)
    const majorHours = [0, 6, 12, 18];
    for (final hour in majorHours) {
      final angle = -math.pi / 2 + (hour / 24.0) * 2 * math.pi;
      final textRadius = outerRadius + strokeWidth / 2 + 10;
      final pos = Offset(
        center.dx + math.cos(angle) * textRadius,
        center.dy + math.sin(angle) * textRadius,
      );

      final hourStr = hour == 0 ? '24' : hour.toString().padLeft(2, '0');
      _drawText(
        canvas,
        hourStr,
        pos,
        10.5,
        FontWeight.w800,
        Colors.white.withValues(alpha: 0.85),
      );
    }

    // 보조 눈금 점 (3, 9, 15, 21시)
    const minorHours = [3, 9, 15, 21];
    final tickPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (final hour in minorHours) {
      final angle = -math.pi / 2 + (hour / 24.0) * 2 * math.pi;
      final tickPos = Offset(
        center.dx + math.cos(angle) * (outerRadius + strokeWidth / 2 + 6),
        center.dy + math.sin(angle) * (outerRadius + strokeWidth / 2 + 6),
      );
      canvas.drawCircle(tickPos, 2.0, tickPaint);
    }

    // 3. 등록된 일정 아크(Arc) 그리기 (생생한 색상 + 발광 글로우)
    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final s in sortedSchedules) {
      final visibleStart = s.startTime.isBefore(dayStart) ? dayStart : s.startTime;
      final visibleEnd = s.endTime.isAfter(dayEnd) ? dayEnd : s.endTime;
      if (!visibleEnd.isAfter(visibleStart)) continue;

      final startMinutes = visibleStart.difference(dayStart).inMinutes;
      final durationMinutes = visibleEnd.difference(visibleStart).inMinutes;

      final startAngle = -math.pi / 2 + (startMinutes / 1440.0) * 2 * math.pi;
      final sweepAngle = (durationMinutes / 1440.0) * 2 * math.pi;

      final scheduleColor = ScheduleColor.colors[s.colorIndex % ScheduleColor.colors.length];

      final arcPaint = Paint()
        ..color = scheduleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: outerRadius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }

    // 4. 현재 시간 표시 바늘
    final currentMinutes = displayTime.hour * 60 + displayTime.minute;
    final currentAngle = -math.pi / 2 + (currentMinutes / 1440.0) * 2 * math.pi;
    final pointerCenter = Offset(
      center.dx + math.cos(currentAngle) * outerRadius,
      center.dy + math.sin(currentAngle) * outerRadius,
    );

    // 포인터 글로우 & 흰색 헤드
    final pointerGlow = Paint()
      ..color = const Color(0xFFFF453A).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pointerCenter, strokeWidth * 0.45, pointerGlow);

    final pointerHead = Paint()..color = Colors.white;
    canvas.drawCircle(pointerCenter, strokeWidth * 0.28, pointerHead);

    // 5. 원 내부 중앙: 대형 시간 & 일정 정보
    final hourStr = displayTime.hour.toString().padLeft(2, '0');
    final minStr = displayTime.minute.toString().padLeft(2, '0');
    final timeFormatted = '$hourStr:$minStr';

    // (1) 대형 현재 시간 (32pt Ultra Bold)
    _drawText(
      canvas,
      timeFormatted,
      center.translate(0, -14),
      32,
      FontWeight.w900,
      Colors.white,
      letterSpacing: -1.2,
    );

    // (2) 일정 배지 (당직 또는 일정 제목)
    if (currentSchedule != null) {
      final s = currentSchedule!;
      final sColor = ScheduleColor.colors[s.colorIndex % ScheduleColor.colors.length];
      final title = s.isShift ? '[당직] ${s.title}' : s.title;

      final textSpan = TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 18),
          width: tp.width + 18,
          height: 22,
        ),
        const Radius.circular(11),
      );

      final pillPaint = Paint()..color = sColor.withValues(alpha: 0.45);
      canvas.drawRRect(pillRect, pillPaint);

      final pillBorder = Paint()
        ..color = sColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawRRect(pillRect, pillBorder);

      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 18 - tp.height / 2));
    } else {
      _drawText(
        canvas,
        '예정된 일정 없음',
        center.translate(0, 16),
        12,
        FontWeight.w600,
        Colors.white54,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    FontWeight weight,
    Color color, {
    double letterSpacing = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    painter.layout();
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _LargeLiquidCirclePainter oldDelegate) => true;
}

// =============================================================================
// 4. 4x6 위젯: 4x2 + 4x4 리퀴드 결합형
// =============================================================================
class CombinedWidgetView extends StatelessWidget {
  final DateTime targetMonth;
  final DateTime targetDay;
  final List<Schedule> schedules;
  final TimeOfDay? displayTime;
  final double? width;
  final double? height;

  const CombinedWidgetView({
    super.key,
    required this.targetMonth,
    required this.targetDay,
    required this.schedules,
    this.displayTime,
    this.width = 360,
    this.height = 540,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: GlassContainer(
        useOwnLayer: true,
        width: width,
        height: height,
        settings: LiquidGlassSettings.ios27Dark,
        shape: const LiquidRoundedSuperellipse(borderRadius: 28),
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF0F172A).withValues(alpha: 0.3),
        glowIntensity: 0.25,
        child: Column(
          children: [
            // 상단: 4x2 캘린더
            SizedBox(
              height: 160,
              child: MonthWidgetView(
                targetMonth: targetMonth,
                schedules: schedules,
                width: double.infinity,
                height: 160,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(color: Colors.white12, height: 1),
            ),
            // 하단: 4x4 원형 시계 차트
            Expanded(
              child: DayCircularWidgetView(
                targetDay: targetDay,
                schedules: schedules,
                displayTime: displayTime,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
