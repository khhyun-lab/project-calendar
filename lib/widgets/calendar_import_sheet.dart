import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import '../services/calendar_sync_service.dart';
import '../stores/schedule_store.dart';
import 'schedule_color_picker.dart';

class CalendarImportSheet extends StatefulWidget {
  final ScheduleStore store;

  const CalendarImportSheet({super.key, required this.store});

  static Future<void> show(BuildContext context, ScheduleStore store) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CalendarImportSheet(store: store),
    );
  }

  @override
  State<CalendarImportSheet> createState() => _CalendarImportSheetState();
}

class _CalendarImportSheetState extends State<CalendarImportSheet> {
  final CalendarSyncService _syncService = CalendarSyncService();

  bool _isLoading = true;
  bool _hasPermission = false;
  List<Calendar> _calendars = [];
  final Set<String> _selectedCalendarIds = {};

  // 기간 선택: 0 = 최근 1개월 ~ 향후 3개월, 1 = 올해 전체 (1년)
  int _rangeOption = 0;
  int _selectedColorIndex = 0; // 파랑

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoading = true);

    final hasPerm = await _syncService.checkAndRequestPermissions();
    if (!hasPerm) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
      return;
    }

    final calendars = await _syncService.getDeviceCalendars();
    if (mounted) {
      setState(() {
        _hasPermission = true;
        _calendars = calendars;
        // 기본적으로 모든 캘린더 선택
        _selectedCalendarIds.addAll(
          calendars.where((c) => c.id != null).map((c) => c.id!),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _import() async {
    if (_selectedCalendarIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가져올 캘린더를 하나 이상 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (_rangeOption == 0) {
      // 최근 1개월 ~ 향후 3개월
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month + 4, 0);
    } else {
      // 올해 전체
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31, 23, 59);
    }

    final importedCount = await _syncService.importEventsFromCalendars(
      calendarIds: _selectedCalendarIds.toList(),
      startDate: startDate,
      endDate: endDate,
      store: widget.store,
      colorIndex: _selectedColorIndex,
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('기기 캘린더에서 총 $importedCount개의 일정을 성공적으로 가져왔습니다!'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타이틀 헤더
            const Row(
              children: [
                Icon(Icons.sync_alt, color: Color(0xFF007AFF), size: 22),
                SizedBox(width: 8),
                Text(
                  '기존 캘린더 일정 가져오기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '구글, 애플 캘린더 및 공휴일 일정을 앱으로 불러옵니다.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('기기 캘린더를 조회하는 중입니다...'),
                    ],
                  ),
                ),
              )
            else if (!_hasPermission)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, size: 44, color: Colors.orange),
                      const SizedBox(height: 10),
                      const Text(
                        '캘린더 접근 권한이 필요합니다.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '기기의 [설정 > 올인원 스케줄]에서 캘린더 접근을 허용해주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12.5),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadCalendars,
                        child: const Text('권한 다시 요청'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_calendars.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    '기기에 등록된 캘린더가 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              // 캘린더 목록 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '불러올 캘린더 선택 (${_selectedCalendarIds.length}/${_calendars.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      setState(() {
                        if (_selectedCalendarIds.length == _calendars.length) {
                          _selectedCalendarIds.clear();
                        } else {
                          _selectedCalendarIds.clear();
                          _selectedCalendarIds.addAll(
                            _calendars.where((c) => c.id != null).map((c) => c.id!),
                          );
                        }
                      });
                    },
                    child: Text(
                      _selectedCalendarIds.length == _calendars.length ? '전체 해제' : '전체 선택',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // 캘린더 체크박스 리스트
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _calendars.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final calendar = _calendars[index];
                    final isChecked = _selectedCalendarIds.contains(calendar.id);

                    return CheckboxListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      value: isChecked,
                      title: Text(
                        calendar.name ?? '이름 없는 캘린더',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: calendar.accountName != null
                          ? Text(
                              calendar.accountName!,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          : null,
                      onChanged: (val) {
                        setState(() {
                          if (val == true && calendar.id != null) {
                            _selectedCalendarIds.add(calendar.id!);
                          } else if (val == false && calendar.id != null) {
                            _selectedCalendarIds.remove(calendar.id!);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 가져올 기간 옵션
              const Text(
                '가져올 기간',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: _rangeOption == 0,
                      label: const Text('최근 1달 ~ 향후 3달 (추천)'),
                      onSelected: (val) {
                        if (val) setState(() => _rangeOption = 0);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      selected: _rangeOption == 1,
                      label: const Text('올해 전체 (1년)'),
                      onSelected: (val) {
                        if (val) setState(() => _rangeOption = 1);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 가져온 일정 대표 색상
              const Text(
                '가져온 일정 표시 색상',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              ScheduleColorPicker(
                selectedIndex: _selectedColorIndex,
                onChanged: (idx) => setState(() => _selectedColorIndex = idx),
              ),

              const SizedBox(height: 20),

              // 가져오기 실행 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.download),
                  label: Text(
                    '${_selectedCalendarIds.length}개 캘린더에서 일정 불러오기',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _selectedCalendarIds.isEmpty ? null : _import,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

