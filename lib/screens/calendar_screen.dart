import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule.dart';
import '../models/schedule_color.dart';
import '../widgets/time_input.dart';
import '../widgets/schedule_color_picker.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 현재는 메모리에 일정 저장
  final List<Schedule> _schedules = [];

  // 해당 날짜와 겹치는 일정 가져오기
  List<Schedule> _getSchedulesForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);

    final dayEnd = DateTime(day.year, day.month, day.day + 1);

    return _schedules.where((schedule) {
      return schedule.startTime.isBefore(dayEnd) &&
          schedule.endTime.isAfter(dayStart);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // 24시간 형식
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // 날짜 비교
  bool _isNextDay(Schedule schedule) {
    return !isSameDay(schedule.startTime, schedule.endTime);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchedules = _getSchedulesForDay(_selectedDay);

    return Scaffold(
      body: Column(
        children: [
          // 월간 캘린더
          TableCalendar<Schedule>(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focusedDay,

            calendarFormat: CalendarFormat.month,

            availableCalendarFormats: const {CalendarFormat.month: 'Month'},

            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),

            calendarStyle: const CalendarStyle(outsideDaysVisible: false),

            // 해당 날짜의 일정 가져오기
            eventLoader: _getSchedulesForDay,

            // 색상 마커
            calendarBuilders: CalendarBuilders<Schedule>(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) {
                  return null;
                }

                return Positioned(
                  bottom: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(3).map((schedule) {
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
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

            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),

          const Divider(),

          // 선택한 날짜
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedDay.year}년 '
                    '${_selectedDay.month}월 '
                    '${_selectedDay.day}일',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => _showScheduleDialog(),
                  icon: const Icon(Icons.add),
                  tooltip: '일정 추가',
                ),
              ],
            ),
          ),

          // 일정 목록
          Expanded(
            child: selectedSchedules.isEmpty
                ? const Center(
                    child: Text(
                      '등록된 일정이 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = selectedSchedules[index];

                      return ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: ScheduleColor.colors[schedule.colorIndex],
                            shape: BoxShape.circle,
                          ),
                        ),

                        title: Text(schedule.title),

                        subtitle: Text(
                          '${_formatTime(schedule.startTime)}'
                          ' - '
                          '${_formatTime(schedule.endTime)}'
                          '${_isNextDay(schedule) ? ' (+1일)' : ''}',
                        ),

                        // 누르면 수정
                        onTap: () {
                          _showScheduleDialog(schedule: schedule);
                        },

                        // 길게 누르면 삭제
                        onLongPress: () {
                          _showDeleteDialog(schedule);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ===================================
  // 일정 추가 및 수정 공통 화면
  // ===================================

  Future<void> _showScheduleDialog({Schedule? schedule}) async {
    final isEditing = schedule != null;

    final titleController = TextEditingController(text: schedule?.title ?? '');

    TimeOfDay? startTime = schedule == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(schedule.startTime);

    TimeOfDay? endTime = schedule == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : TimeOfDay.fromDateTime(schedule.endTime);

    int selectedColorIndex = schedule?.colorIndex ?? 0;

    // 수정 시 기존 시작 날짜 유지
    final baseDate = schedule?.startTime ?? _selectedDay;

    final result = await showDialog<Schedule>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 다음 날 종료 여부 계산
            bool isNextDay = false;

            if (startTime != null && endTime != null) {
              final startMinutes = startTime!.hour * 60 + startTime!.minute;

              final endMinutes = endTime!.hour * 60 + endTime!.minute;

              isNextDay = endMinutes <= startMinutes;
            }

            return AlertDialog(
              title: Text(isEditing ? '일정 수정' : '일정 추가'),

              // 키보드가 열려도 스크롤 가능
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 일정 제목
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '일정 제목',
                        hintText: '예: 출근, 운동, 당직',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '시작 시간',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    TimeInput(
                      initialTime:
                          startTime ?? const TimeOfDay(hour: 9, minute: 0),
                      onChanged: (time) {
                        setDialogState(() {
                          startTime = time;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '종료 시간',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    TimeInput(
                      initialTime:
                          endTime ?? const TimeOfDay(hour: 10, minute: 0),
                      onChanged: (time) {
                        setDialogState(() {
                          endTime = time;
                        });
                      },
                    ),

                    // 자정을 넘기는 경우
                    if (isNextDay)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '종료 시간이 다음 날입니다. (+1일)',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 24),

                    const Text(
                      '일정 색상',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    ScheduleColorPicker(
                      selectedIndex: selectedColorIndex,
                      onChanged: (index) {
                        setDialogState(() {
                          selectedColorIndex = index;
                        });
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
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

                    // 시작 날짜와 시간
                    final startDateTime = DateTime(
                      baseDate.year,
                      baseDate.month,
                      baseDate.day,
                      startTime!.hour,
                      startTime!.minute,
                    );

                    // 종료 날짜와 시간
                    var endDateTime = DateTime(
                      baseDate.year,
                      baseDate.month,
                      baseDate.day,
                      endTime!.hour,
                      endTime!.minute,
                    );

                    // 종료 시간이 빠르거나 같으면 익일
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
                      id:
                          schedule?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
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

    titleController.dispose();

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (isEditing) {
        final index = _schedules.indexWhere((item) => item.id == result.id);

        if (index != -1) {
          _schedules[index] = result;
        }
      } else {
        _schedules.add(result);
      }
    });
  }

  // ===================================
  // 일정 삭제
  // ===================================

  Future<void> _showDeleteDialog(Schedule schedule) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('일정 삭제'),
          content: Text('"${schedule.title}" 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (shouldDelete == true) {
      setState(() {
        _schedules.removeWhere((item) => item.id == schedule.id);
      });
    }
  }
}
