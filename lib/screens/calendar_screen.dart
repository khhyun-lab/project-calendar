import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 현재 달력에서 보고 있는 날짜
  DateTime _focusedDay = DateTime.now();

  // 사용자가 선택한 날짜
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          // 달력에서 이동 가능한 범위
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2035, 12, 31),

          // 현재 보고 있는 날짜
          focusedDay: _focusedDay,

          // 선택된 날짜를 판단
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },

          // 날짜를 눌렀을 때
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          // 다음 달 / 이전 달로 이동했을 때
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },

          // 월간 달력으로 고정
          calendarFormat: CalendarFormat.month,

          // Format 버튼 숨김
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },

          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),

          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
          ),
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
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
        ),

        const Expanded(
          child: Center(
            child: Text(
              '등록된 일정이 없습니다.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}