import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule.dart';
import '../models/schedule_color.dart';
import '../stores/schedule_store.dart';
import '../widgets/schedule_color_picker.dart';
import '../widgets/time_input.dart';

class CalendarScreen extends StatefulWidget {
  final ScheduleStore store;

  const CalendarScreen({super.key, required this.store});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
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

  List<Schedule> _getSchedulesForDay(DateTime day) {
    return widget.store.getSchedulesForDay(day);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isNextDay(Schedule schedule) {
    return !isSameDay(schedule.startTime, schedule.endTime);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchedules = _getSchedulesForDay(_selectedDay);

    return Scaffold(
      body: Stack(
        children: [
          // 1. 반투명 글래스가 가장 아름답게 투과되는 애플 감성 소프트 앰비언트 배경
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE5EEFB), // 은은한 스카이블루 틴트
                    Color(0xFFEDE8F7), // 은은한 라벤더 틴트
                    Color(0xFFF4F6F9), // 맑은 쿨 화이트
                  ],
                ),
              ),
            ),
          ),

          // 2. 반투명 글래스 본문 레이아웃
          SafeArea(
            child: Column(
              children: [
                // 상단 헤더 (< 2026년 11월 >, 오늘)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_focusedDay.year}년 ${_focusedDay.month}월',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1C1E),
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_left, size: 22, color: Color(0xFF007AFF)),
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                              });
                            },
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_right, size: 22, color: Color(0xFF007AFF)),
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                              });
                            },
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
                                final now = DateTime.now();
                                setState(() {
                                  _selectedDay = now;
                                  _focusedDay = now;
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
                ),

                // 2. 뒤 배경이 맑게 비치는 ‘반투명 프로스티드 글래스 달력 보드’
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          // 완전 불투명이 아닌 58% 투명도의 맑은 반투명 우윳빛 유리
                          color: Colors.white.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(22),
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
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: TableCalendar<Schedule>(
                          firstDay: DateTime(2020, 1, 1),
                          lastDay: DateTime(2035, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: CalendarFormat.month,
                          headerVisible: false,
                          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                          eventLoader: _getSchedulesForDay,
                          rowHeight: 46,

                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },

                          calendarBuilders: CalendarBuilders<Schedule>(
                            // 요일 헤더
                            dowBuilder: (context, day) {
                              final isSunday = day.weekday == DateTime.sunday;
                              final isSaturday = day.weekday == DateTime.saturday;
                              final labels = ['월', '화', '수', '목', '금', '토', '일'];
                              final text = labels[day.weekday - 1];

                              Color dowColor = const Color(0xFF6E6E73);
                              if (isSunday) dowColor = const Color(0xFFFF3B30);
                              if (isSaturday) dowColor = const Color(0xFF007AFF);

                              return Center(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: dowColor,
                                  ),
                                ),
                              );
                            },

                            // 선택된 날짜 (테두리 없는 순수 반투명 리퀴드 글래스 하이라이트)
                            selectedBuilder: (context, day, focusedDay) {
                              final isToday = isSameDay(day, DateTime.now());
                              final isSunday = day.weekday == DateTime.sunday;
                              final isSaturday = day.weekday == DateTime.saturday;

                              Color highlightColor = const Color(0xFF007AFF);
                              if (isToday) highlightColor = const Color(0xFFFF3B30);
                              else if (isSunday) highlightColor = const Color(0xFFFF3B30);
                              else if (isSaturday) highlightColor = const Color(0xFF007AFF);

                              return Center(
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        // 테두리 없이 맑은 반투명 리퀴드 글래스 틴트
                                        color: highlightColor.withValues(alpha: 0.16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: highlightColor.withValues(alpha: 0.22),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          color: highlightColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },

                            // 오늘 날짜 (미선택 시 은은한 레드 링)
                            todayBuilder: (context, day, focusedDay) {
                              return Center(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Color(0xFFFF3B30),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              );
                            },

                            // 기본 날짜 셀 (가독성 100% 또렷한 텍스트)
                            defaultBuilder: (context, day, focusedDay) {
                              final isSunday = day.weekday == DateTime.sunday;
                              final isSaturday = day.weekday == DateTime.saturday;

                              Color dayColor = const Color(0xFF1C1C1E);
                              if (isSunday) dayColor = const Color(0xFFFF3B30);
                              if (isSaturday) dayColor = const Color(0xFF007AFF);

                              return Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: dayColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            },

                            // 일정 마커 도트
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty) return null;

                              return Positioned(
                                bottom: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: events.take(4).map((schedule) {
                                    return Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(horizontal: 1.2),
                                      decoration: BoxDecoration(
                                        color: ScheduleColor.colors[schedule.colorIndex],
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. 선택 날짜 정보 헤더 & [일정 추가] 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDay.month}월 ${_selectedDay.day}일 일정 (${selectedSchedules.length})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.4,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showScheduleDialog(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.add, size: 16, color: Color(0xFF007AFF)),
                                    SizedBox(width: 4),
                                    Text(
                                      '일정 추가',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 4. 뒤가 은은하게 비치는 ‘반투명 프로스티드 글래스 일정 카드 목록’
                Expanded(
                  child: selectedSchedules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 38,
                                color: Color(0xFF9E9EA7),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '등록된 일정이 없습니다.',
                                style: TextStyle(
                                  color: Color(0xFF6E6E73),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: selectedSchedules.length,
                          itemBuilder: (context, index) {
                            final schedule = selectedSchedules[index];
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
                                      // 반투명 62% 글래스 서피스
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
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => _showScheduleDialog(schedule: schedule),
                                        onLongPress: () => _showDeleteDialog(schedule),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              // 컬러 바
                                              Container(
                                                width: 4.5,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: ScheduleColor.colors[schedule.colorIndex],
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
                                                          : '${_formatTime(schedule.startTime)} ~ ${_formatTime(schedule.endTime)}${_isNextDay(schedule) ? ' (+1일)' : ''}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(0xFF6E6E73),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                size: 18,
                                                color: Color(0xFF9E9EA7),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 일정 추가 및 수정 다이얼로그 (iOS 라운드 스타일)
  Future<void> _showScheduleDialog({Schedule? schedule}) async {
    final titleController = TextEditingController(text: schedule?.title ?? '');

    TimeOfDay? startTime = schedule == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(schedule.startTime);

    TimeOfDay? endTime = schedule == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : TimeOfDay.fromDateTime(schedule.endTime);

    int selectedColorIndex = schedule?.colorIndex ?? 0;
    final baseDate = schedule?.startTime ?? _selectedDay;

    final result = await showDialog<Schedule>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isNextDay = false;

            if (startTime != null && endTime != null) {
              final startMinutes = startTime!.hour * 60 + startTime!.minute;
              final endMinutes = endTime!.hour * 60 + endTime!.minute;
              isNextDay = endMinutes <= startMinutes;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Text(
                schedule == null ? '일정 추가' : '일정 수정',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '일정 제목',
                        hintText: '예: 미팅, 운동, 진료',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('시작 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TimeInput(
                      initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                      onChanged: (time) {
                        setDialogState(() => startTime = time);
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text('종료 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TimeInput(
                      initialTime: endTime ?? const TimeOfDay(hour: 10, minute: 0),
                      onChanged: (time) {
                        setDialogState(() => endTime = time);
                      },
                    ),
                    if (isNextDay)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '종료 시간이 다음 날입니다. (+1일)',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text('일정 색상', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ScheduleColorPicker(
                      selectedIndex: selectedColorIndex,
                      onChanged: (index) {
                        setDialogState(() => selectedColorIndex = index);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty || startTime == null || endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목과 올바른 시간을 입력하세요.')),
                      );
                      return;
                    }

                    final startDateTime = DateTime(
                      baseDate.year,
                      baseDate.month,
                      baseDate.day,
                      startTime!.hour,
                      startTime!.minute,
                    );

                    var endDateTime = DateTime(
                      baseDate.year,
                      baseDate.month,
                      baseDate.day,
                      endTime!.hour,
                      endTime!.minute,
                    );

                    if (!endDateTime.isAfter(startDateTime)) {
                      endDateTime = DateTime(
                        baseDate.year,
                        baseDate.month,
                        baseDate.day + 1,
                        endTime!.hour,
                        endTime!.minute,
                      );
                    }

                    final newSchedule = Schedule(
                      id: schedule?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                      title: title,
                      startTime: startDateTime,
                      endTime: endDateTime,
                      colorIndex: selectedColorIndex,
                    );

                    Navigator.pop(dialogContext, newSchedule);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    widget.store.saveSchedule(result);
  }

  // 일정 삭제
  Future<void> _showDeleteDialog(Schedule schedule) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('일정 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text('"${schedule.title}" 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) return;
    widget.store.deleteSchedule(schedule.id);
  }
}
