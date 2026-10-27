import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/schedule_color.dart';
import '../stores/schedule_store.dart';
import '../widgets/circular_schedule.dart';

class DayScreen extends StatefulWidget {
  final ScheduleStore store;

  const DayScreen({super.key, required this.store});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _changeDay(int days) {
    setState(() {
      _selectedDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day + days,
      );
    });
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final rangeStart = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    final rangeEnd = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day + 1,
    );

    final schedules = widget.store.getSchedulesForDay(_selectedDay);

    return Scaffold(
      body: Stack(
        children: [
          // 배경: 은은한 앰비언트 그라데이션
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE5EEFB),
                    Color(0xFFEDE8F7),
                    Color(0xFFF4F6F9),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              // 하단 플로팅 탭 바(높이 70px)에 가려지지 않도록 120px 여유 하단 패딩 확보!
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                // 1. 날짜 이동 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_selectedDay.year}년 ${_selectedDay.month}월 ${_selectedDay.day}일',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chevron_left, size: 22, color: Color(0xFF007AFF)),
                          onPressed: () => _changeDay(-1),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chevron_right, size: 22, color: Color(0xFF007AFF)),
                          onPressed: () => _changeDay(1),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 0.7,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _selectedDay = DateTime.now();
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              child: Text(
                                '오늘',
                                style: TextStyle(
                                  color: Color(0xFF007AFF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. 반투명 글래스 원형 차트 보드
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircularSchedule(
                        rangeStart: rangeStart,
                        rangeEnd: rangeEnd,
                        schedules: schedules,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. 일정 목록 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '등록된 일정 (${schedules.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C1C1E),
                      letterSpacing: -0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (schedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        '등록된 일정이 없습니다.',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // 4. 반투명 글래스 일정 목록 카드들 (스크롤 시 끝까지 온전히 보임!)
                ...schedules.map((schedule) {
                  final nextDay = !DateUtils.isSameDay(
                    schedule.startTime,
                    schedule.endTime,
                  );

                  final colorIndex = schedule.colorIndex.clamp(
                    0,
                    ScheduleColor.colors.length - 1,
                  );

                  final isOffDay = schedule.startTime.hour == 0 &&
                      schedule.startTime.minute == 0 &&
                      schedule.endTime.hour == 23 &&
                      schedule.endTime.minute == 59;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // 컬러 바
                              Container(
                                width: 4.5,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: ScheduleColor.colors[colorIndex],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          schedule.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF1C1C1E),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        if (schedule.isShift) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              '근무',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xFF007AFF),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isOffDay
                                          ? '종일 / 휴무'
                                          : '${_formatTime(schedule.startTime)} ~ ${_formatTime(schedule.endTime)}${nextDay ? ' (+1일)' : ''}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6E6E73),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
