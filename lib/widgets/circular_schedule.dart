import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../models/schedule_color.dart';

class CircularSchedule extends StatelessWidget {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<Schedule> schedules;

  const CircularSchedule({
    super.key,
    required this.rangeStart,
    required this.rangeEnd,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _CircularSchedulePainter(
          rangeStart: rangeStart,
          schedules: schedules,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          textColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _CircularSchedulePainter extends CustomPainter {
  final DateTime rangeStart;
  final List<Schedule> schedules;
  final Color backgroundColor;
  final Color textColor;

  _CircularSchedulePainter({
    required this.rangeStart,
    required this.schedules,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.30;
    final strokeWidth = size.width * 0.055;

    final dayStart = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );

    final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day + 1);

    // 시간순 정렬
    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // 일정별 링 배치
    final ringEnds = <DateTime>[];
    final labels = <_TimeLabel>[];

    for (final schedule in sortedSchedules) {
      final visibleStart = schedule.startTime.isBefore(dayStart)
          ? dayStart
          : schedule.startTime;

      final visibleEnd = schedule.endTime.isAfter(dayEnd)
          ? dayEnd
          : schedule.endTime;

      if (!visibleEnd.isAfter(visibleStart)) {
        continue;
      }

      // 시간이 겹치지 않는 링 찾기
      int ringIndex = 0;

      while (ringIndex < ringEnds.length &&
          ringEnds[ringIndex].isAfter(visibleStart)) {
        ringIndex++;
      }

      if (ringIndex == ringEnds.length) {
        ringEnds.add(visibleEnd);
      } else {
        ringEnds[ringIndex] = visibleEnd;
      }

      // 링 간격
      final radius = outerRadius - ringIndex * (strokeWidth + 5);

      if (radius <= strokeWidth) {
        continue;
      }

      final startMinutes = visibleStart.difference(dayStart).inMinutes;

      final durationMinutes = visibleEnd.difference(visibleStart).inMinutes;

      final startAngle = -math.pi / 2 + (startMinutes / 1440) * 2 * math.pi;

      final sweepAngle = (durationMinutes / 1440) * 2 * math.pi;

      final colorIndex = schedule.colorIndex.clamp(
        0,
        ScheduleColor.colors.length - 1,
      );

      final rect = Rect.fromCircle(center: center, radius: radius);

      // 링 배경
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, radius, backgroundPaint);

      // 일정 색상
      final schedulePaint = Paint()
        ..color = ScheduleColor.colors[colorIndex]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, schedulePaint);

      // 시간 라벨은 바깥쪽에 표시
      labels.add(_TimeLabel(time: visibleStart, angle: startAngle));

      labels.add(_TimeLabel(time: visibleEnd, angle: startAngle + sweepAngle));
    }

    // 일정이 없어도 기본 원 표시
    if (ringEnds.isEmpty) {
      final paint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, outerRadius, paint);
    }

    // 일정 시작/종료 시간 표시
    for (final label in labels) {
      _drawTimeLabel(canvas, center, outerRadius, label);
    }

    // 중앙 날짜
    _drawText(
      canvas,
      '${dayStart.month}월 ${dayStart.day}일',
      center.translate(0, -15),
      21,
      FontWeight.bold,
    );

    _drawText(canvas, '하루 일정', center.translate(0, 15), 14, FontWeight.normal);
  }

  void _drawTimeLabel(
    Canvas canvas,
    Offset center,
    double radius,
    _TimeLabel label,
  ) {
    final distance = radius + 35;

    final position = Offset(
      center.dx + math.cos(label.angle) * distance,
      center.dy + math.sin(label.angle) * distance,
    );

    final text =
        '${label.time.hour.toString().padLeft(2, '0')}:'
        '${label.time.minute.toString().padLeft(2, '0')}';

    _drawText(canvas, text, position, 11, FontWeight.bold);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    painter.layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CircularSchedulePainter oldDelegate) {
    return true;
  }
}

class _TimeLabel {
  final DateTime time;
  final double angle;

  _TimeLabel({required this.time, required this.angle});
}
