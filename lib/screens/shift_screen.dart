import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../models/schedule_color.dart';
import '../models/shift_type.dart';
import '../stores/schedule_store.dart';
import '../widgets/schedule_color_picker.dart';
import '../widgets/time_input.dart';

class ShiftScreen extends StatefulWidget {
  final ScheduleStore store;

  const ShiftScreen({super.key, required this.store});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // 사용자가 정의한 근무 형태 목록 (자유롭게 추가/수정/삭제 가능)
  late List<ShiftType> _shiftTypes;

  // 현재 선택된 스탬프 근무 (선택 후 달력 날짜 탭 시 즉시 칠해짐)
  ShiftType? _selectedStampType;
  bool _isEraserMode = false;

  @override
  void initState() {
    super.initState();
    _shiftTypes = List.from(ShiftType.initialTypes);
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

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  int get _daysInMonth {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  // 특정 일자의 근무 스케줄 찾기
  Schedule? _getShiftForDay(DateTime day) {
    final schedules = widget.store.getSchedulesForDay(day);
    for (final s in schedules) {
      if (s.isShift) return s;
    }
    return null;
  }

  // 날짜 탭 시 스탬프 찍기 또는 수정
  void _onDayTapped(DateTime day) {
    final existingShift = _getShiftForDay(day);

    if (_isEraserMode) {
      if (existingShift != null) {
        widget.store.deleteSchedule(existingShift.id);
      }
      return;
    }

    if (_selectedStampType != null) {
      _applySingleShift(day, _selectedStampType!);
      return;
    }

    // 선택된 스탬프가 없으면 빠른 선택 팝업 표시
    _showDayShiftPicker(day, existingShift);
  }

  void _applySingleShift(DateTime day, ShiftType type) {
    final existing = _getShiftForDay(day);
    if (existing != null) {
      widget.store.deleteSchedule(existing.id);
    }

    if (type.isOff) {
      // OFF/휴무는 시간 일정 대신 캘린더에 OFF 표시용으로 00:00~00:00 등록
      widget.store.saveSchedule(
        Schedule(
          id: 'shift_${day.year}_${day.month}_${day.day}',
          title: type.name,
          startTime: DateTime(day.year, day.month, day.day),
          endTime: DateTime(day.year, day.month, day.day, 23, 59),
          colorIndex: type.colorIndex,
          isShift: true,
          shiftTypeId: type.id,
        ),
      );
      return;
    }

    final start = type.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    final end = type.endTime ?? const TimeOfDay(hour: 18, minute: 0);

    final startDateTime = DateTime(day.year, day.month, day.day, start.hour, start.minute);
    DateTime endDateTime;
    if (type.isNextDay) {
      endDateTime = DateTime(day.year, day.month, day.day + 1, end.hour, end.minute);
    } else {
      endDateTime = DateTime(day.year, day.month, day.day, end.hour, end.minute);
    }

    widget.store.saveSchedule(
      Schedule(
        id: 'shift_${day.year}_${day.month}_${day.day}',
        title: type.name,
        startTime: startDateTime,
        endTime: endDateTime,
        colorIndex: type.colorIndex,
        isShift: true,
        shiftTypeId: type.id,
      ),
    );
  }

  // 날짜 탭 시 근무 선택 바텀시트
  void _showDayShiftPicker(DateTime day, Schedule? current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.month}월 ${day.day}일 근무 선택',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._shiftTypes.map((type) {
                    return ActionChip(
                      avatar: CircleAvatar(
                        backgroundColor: ScheduleColor.colors[type.colorIndex],
                        radius: 6,
                      ),
                      label: Text(type.name),
                      onPressed: () {
                        _applySingleShift(day, type);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                  if (current != null)
                    ActionChip(
                      avatar: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('근무 삭제', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        widget.store.deleteSchedule(current.id);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // 등록된 근무 목록 전체 관리 (기본 주간/야간/당직/OFF 포함 수정 및 삭제)
  void _showShiftTypeManageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '근무 목록 관리',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('새 근무 추가'),
                        onPressed: () async {
                          Navigator.pop(sheetCtx);
                          await _editShiftTypeDialog();
                          _showShiftTypeManageSheet();
                        },
                      ),
                    ],
                  ),
                  const Text(
                    '필요 없는 기본 근무(주간, 야간, 당직, OFF 등)는 삭제하거나 수정할 수 있습니다.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (_shiftTypes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '등록된 근무가 없습니다.\n우측 상단의 "새 근무 추가"를 눌러보세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _shiftTypes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final type = _shiftTypes[idx];
                          final timeStr = type.isOff
                              ? '휴무 / OFF'
                              : '${type.startTime?.format(context) ?? ''} ~ ${type.endTime?.format(context) ?? ''}';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: ScheduleColor.colors[type.colorIndex],
                              radius: 12,
                              child: Text(
                                type.name.isNotEmpty ? type.name[0] : '',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                  tooltip: '수정',
                                  onPressed: () async {
                                    Navigator.pop(sheetCtx);
                                    await _editShiftTypeDialog(type: type);
                                    _showShiftTypeManageSheet();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  tooltip: '삭제',
                                  onPressed: () {
                                    setState(() {
                                      _shiftTypes.removeAt(idx);
                                      if (_selectedStampType?.id == type.id) {
                                        _selectedStampType = null;
                                      }
                                    });
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 근무 형태 추가 및 편집 다이얼로그
  Future<void> _editShiftTypeDialog({ShiftType? type}) async {
    final titleController = TextEditingController(text: type?.name ?? '');
    TimeOfDay startTime = type?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = type?.endTime ?? const TimeOfDay(hour: 18, minute: 0);
    int colorIndex = type?.colorIndex ?? 0;
    bool isOff = type?.isOff ?? false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(type == null ? '근무 추가' : '근무 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '근무 이름 (예: 당직, 오전, A조, 특근)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('휴무 / OFF 여부'),
                  value: isOff,
                  onChanged: (val) => setDialogState(() => isOff = val),
                ),
                if (!isOff) ...[
                  const SizedBox(height: 8),
                  const Text('근무 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TimeInput(
                        initialTime: startTime,
                        onChanged: (t) {
                          if (t != null) setDialogState(() => startTime = t);
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('~'),
                      ),
                      TimeInput(
                        initialTime: endTime,
                        onChanged: (t) {
                          if (t != null) setDialogState(() => endTime = t);
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Text('색상', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ScheduleColorPicker(
                  selectedIndex: colorIndex,
                  onChanged: (idx) => setDialogState(() => colorIndex = idx),
                ),
              ],
            ),
          ),
          actions: [
            if (type != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _shiftTypes.removeWhere((t) => t.id == type.id);
                    if (_selectedStampType?.id == type.id) {
                      _selectedStampType = null;
                    }
                  });
                  Navigator.pop(dialogCtx);
                },
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final name = titleController.text.trim();
                if (name.isEmpty) return;

                final updated = ShiftType(
                  id: type?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  startTime: isOff ? null : startTime,
                  endTime: isOff ? null : endTime,
                  colorIndex: colorIndex,
                  isOff: isOff,
                );

                setState(() {
                  if (type == null) {
                    _shiftTypes.add(updated);
                  } else {
                    final idx = _shiftTypes.indexWhere((t) => t.id == type.id);
                    if (idx != -1) _shiftTypes[idx] = updated;
                  }
                });
                Navigator.pop(dialogCtx);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  // 심플한 커스텀 로테이션 반복 등록 다이얼로그 (2달, 1달, N일 등)
  void _showRotationDialog() {
    DateTime startDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final pattern = <ShiftType>[];
    int repeatMonths = 2; // 기본 2달 로테이션

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.loop, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '로테이션 자동 반복 설정',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 시작일 및 반복 개월 수
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(
                            '시작일: ${startDate.year}.${startDate.month}.${startDate.day}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setSheetState(() => startDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: repeatMonths,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1달 반복')),
                          DropdownMenuItem(value: 2, child: Text('2달 로테이션')),
                          DropdownMenuItem(value: 3, child: Text('3달 로테이션')),
                          DropdownMenuItem(value: 6, child: Text('6달 반복')),
                          DropdownMenuItem(value: 12, child: Text('1년 반복')),
                        ],
                        onChanged: (val) {
                          if (val != null) setSheetState(() => repeatMonths = val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '순환할 순서대로 터치 (${pattern.length}개)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (pattern.isNotEmpty)
                        TextButton(
                          onPressed: () => setSheetState(() => pattern.clear()),
                          child: const Text('비우기', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 현재 만든 패턴 시각화 (가로 나열)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: pattern.isEmpty
                      ? const Center(
                          child: Text(
                            '아래 근무를 순서대로 눌러 패턴을 만드세요 (예: 주-야-비)',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pattern.length,
                          separatorBuilder: (_, __) => const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
                          itemBuilder: (context, idx) {
                            final shift = pattern[idx];
                            return Center(
                              child: Chip(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: ScheduleColor.colors[shift.colorIndex].withValues(alpha: 0.2),
                                label: Text(shift.name, style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close, size: 12),
                                onDeleted: () => setSheetState(() => pattern.removeAt(idx)),
                              ),
                            );
                          },
                        ),
                  ),

                  const SizedBox(height: 12),

                  // 근무 추가 팔레트
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _shiftTypes.map((type) {
                      return ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: ScheduleColor.colors[type.colorIndex],
                          radius: 6,
                        ),
                        label: Text(type.name),
                        onPressed: () => setSheetState(() => pattern.add(type)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 등록 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text('$repeatMonths개월 로테이션 연속 등록하기'),
                      onPressed: pattern.isEmpty ? null : () {
                        _applyRotation(startDate, pattern, repeatMonths);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 로테이션을 캘린더에 N개월 동안 연속 반복 등록
  void _applyRotation(DateTime startDate, List<ShiftType> pattern, int repeatMonths) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final endDate = DateTime(start.year, start.month + repeatMonths, 1).subtract(const Duration(days: 1));

    widget.store.clearShiftsInRange(start, endDate);

    final newSchedules = <Schedule>[];
    final cycleLen = pattern.length;

    var curr = start;
    int dayCount = 0;

    while (!curr.isAfter(endDate)) {
      final shift = pattern[dayCount % cycleLen];

      if (shift.isOff) {
        newSchedules.add(
          Schedule(
            id: 'shift_${curr.year}_${curr.month}_${curr.day}',
            title: shift.name,
            startTime: DateTime(curr.year, curr.month, curr.day),
            endTime: DateTime(curr.year, curr.month, curr.day, 23, 59),
            colorIndex: shift.colorIndex,
            isShift: true,
            shiftTypeId: shift.id,
          ),
        );
      } else {
        final st = shift.startTime ?? const TimeOfDay(hour: 9, minute: 0);
        final et = shift.endTime ?? const TimeOfDay(hour: 18, minute: 0);
        final startDateTime = DateTime(curr.year, curr.month, curr.day, st.hour, st.minute);
        final endDateTime = shift.isNextDay
            ? DateTime(curr.year, curr.month, curr.day + 1, et.hour, et.minute)
            : DateTime(curr.year, curr.month, curr.day, et.hour, et.minute);

        newSchedules.add(
          Schedule(
            id: 'shift_${curr.year}_${curr.month}_${curr.day}',
            title: shift.name,
            startTime: startDateTime,
            endTime: endDateTime,
            colorIndex: shift.colorIndex,
            isShift: true,
            shiftTypeId: shift.id,
          ),
        );
      }

      curr = curr.add(const Duration(days: 1));
      dayCount++;
    }

    widget.store.saveMultipleSchedules(newSchedules);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$repeatMonths개월간의 로테이션(${newSchedules.length}건)이 등록되었습니다!'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  // 해당 월 전체 삭제
  void _clearMonth() {
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('근무표 초기화'),
        content: Text('${_currentMonth.month}월에 등록된 모든 근무를 지우시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              widget.store.clearShiftsInRange(start, end);
              Navigator.pop(ctx);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7; // 일요일=0
    final totalCells = firstDayWeekday + _daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              '${_currentMonth.year}년 ${_currentMonth.month}월',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              icon: const Icon(Icons.loop, size: 18),
              label: const Text(
                '로테이션 반복',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _showRotationDialog,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: '이번 달 근무 삭제',
            onPressed: _clearMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          // 요일 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: const [
                Expanded(child: Center(child: Text('일', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('월', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('화', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('수', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('목', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('금', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('토', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const Divider(height: 1),

          // 심플한 달력 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(6),
              physics: const ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.88,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: totalRows * 7,
              itemBuilder: (context, index) {
                final dayNumber = index - firstDayWeekday + 1;
                if (dayNumber < 1 || dayNumber > _daysInMonth) {
                  return const SizedBox.shrink(); // 빈 칸
                }

                final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final shift = _getShiftForDay(date);
                final isToday = DateUtils.isSameDay(date, DateTime.now());
                final isSunday = (index % 7) == 0;
                final isSaturday = (index % 7) == 6;

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _onDayTapped(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: shift != null
                          ? ScheduleColor.colors[shift.colorIndex].withValues(alpha: 0.16)
                          : (isToday ? Colors.blue.shade50 : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday
                            ? Colors.blue
                            : (shift != null
                                ? ScheduleColor.colors[shift.colorIndex].withValues(alpha: 0.6)
                                : Colors.grey.shade200),
                        width: isToday ? 1.8 : 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isSunday ? Colors.red : (isSaturday ? Colors.blue : Colors.black87),
                          ),
                        ),
                        const Spacer(),
                        if (shift != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: ScheduleColor.colors[shift.colorIndex],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              shift.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 하단: 근무 스탬프 바 & 관리
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedStampType != null
                              ? '[${_selectedStampType!.name}] 선택됨 ➔ 날짜를 눌러 찍기'
                              : (_isEraserMode ? '지우개 모드 ➔ 날짜를 눌러 지우기' : '근무를 선택하거나 날짜를 눌러 입력하세요'),
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedStampType != null
                                ? ScheduleColor.colors[_selectedStampType!.colorIndex]
                                : (_isEraserMode ? Colors.red : Colors.grey.shade700),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        icon: const Icon(Icons.settings, size: 14),
                        label: const Text('근무 편집/삭제', style: TextStyle(fontSize: 12)),
                        onPressed: _showShiftTypeManageSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // 지우개 칩
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        selected: _isEraserMode,
                        avatar: const Icon(Icons.cleaning_services, size: 14),
                        label: const Text('지우개'),
                        onSelected: (val) {
                          setState(() {
                            _isEraserMode = val;
                            if (val) _selectedStampType = null;
                          });
                        },
                      ),

                      // 사용자 정의 근무 칩 목록
                      ..._shiftTypes.map((type) {
                        final isSelected = !_isEraserMode && _selectedStampType?.id == type.id;
                        return InkWell(
                          onLongPress: () => _editShiftTypeDialog(type: type),
                          child: ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            selected: isSelected,
                            backgroundColor: ScheduleColor.colors[type.colorIndex].withValues(alpha: 0.15),
                            selectedColor: ScheduleColor.colors[type.colorIndex],
                            avatar: CircleAvatar(
                              backgroundColor: isSelected ? Colors.white : ScheduleColor.colors[type.colorIndex],
                              radius: 5,
                            ),
                            label: Text(
                              type.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _isEraserMode = false;
                                _selectedStampType = selected ? type : null;
                              });
                            },
                          ),
                        );
                      }),

                      // 빠른 근무 추가 칩
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.add, size: 14),
                        label: const Text('추가'),
                        onPressed: () => _editShiftTypeDialog(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
