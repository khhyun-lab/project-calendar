import 'package:flutter/material.dart';

import '../stores/schedule_store.dart';
import '../services/widget_service.dart';
import '../widgets/home_widget_views.dart';
import '../widgets/time_input.dart';

class WidgetPreviewScreen extends StatefulWidget {
  final ScheduleStore store;

  const WidgetPreviewScreen({super.key, required this.store});

  @override
  State<WidgetPreviewScreen> createState() => _WidgetPreviewScreenState();
}

class _WidgetPreviewScreenState extends State<WidgetPreviewScreen> {
  int _selectedTab = 0; // 0: 4x2, 1: 4x4, 2: 4x6
  TimeOfDay _customTime = TimeOfDay.now();
  bool _useCustomTime = false;
  bool _isSyncing = false;

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

  Future<void> _syncToHomeWidget() async {
    setState(() => _isSyncing = true);

    await WidgetService.syncAllWidgets(
      store: widget.store,
      customTime: _useCustomTime ? _customTime : null,
    );

    if (!mounted) return;

    setState(() => _isSyncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('4x2, 4x4, 4x6 홈 화면 위젯에 데이터가 성공적으로 반영되었습니다!'),
        backgroundColor: Color(0xFF007AFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final allSchedules = widget.store.schedules;
    final displayTime = _useCustomTime ? _customTime : TimeOfDay.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '홈 화면 위젯 설정 (4x2, 4x4, 4x6)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. 위젯 종류 세그먼트 버튼
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('4x2 캘린더')),
              ButtonSegment(value: 1, label: Text('4x4 원형하루')),
              ButtonSegment(value: 2, label: Text('4x6 결합형')),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (set) {
              setState(() => _selectedTab = set.first);
            },
          ),

          const SizedBox(height: 18),

          // 2. 위젯 규격 안내 텍스트
          Row(
            children: [
              const Icon(Icons.widgets_outlined, size: 18, color: Color(0xFF007AFF)),
              const SizedBox(width: 6),
              Text(
                _selectedTab == 0
                    ? '4x2 위젯: 1달치 일정 및 달력 정보'
                    : (_selectedTab == 1
                        ? '4x4 위젯: 24시간 원형 하루 일정 (시간 설정 가능)'
                        : '4x6 위젯: 4x2(달력) + 4x4(원형) 올인원 결합'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. 실제 위젯 미리보기 프레임
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _selectedTab == 0
                  ? MonthWidgetView(
                      targetMonth: now,
                      schedules: allSchedules,
                    )
                  : (_selectedTab == 1
                      ? DayCircularWidgetView(
                          targetDay: now,
                          schedules: allSchedules,
                          displayTime: displayTime,
                        )
                      : CombinedWidgetView(
                          targetMonth: now,
                          targetDay: now,
                          schedules: allSchedules,
                          displayTime: displayTime,
                        )),
            ),
          ),

          const SizedBox(height: 24),

          // 4. 4x4 및 4x6용 "원형 일정 시간 설정" 컨트롤 (요구사항 4번)
          if (_selectedTab != 0) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: Color(0xFF007AFF)),
                        SizedBox(width: 8),
                        Text(
                          '원형 위젯 표시 시간 설정',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '위젯에 표시될 기준 시간을 사용자가 직접 지정할 수 있습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('특정 시간대로 고정 설정'),
                      subtitle: Text(_useCustomTime ? '지정된 시간: ${_customTime.format(context)}' : '현재 실시간으로 표시'),
                      value: _useCustomTime,
                      onChanged: (val) {
                        setState(() => _useCustomTime = val);
                      },
                    ),
                    if (_useCustomTime) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('기준 시간: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          TimeInput(
                            initialTime: _customTime,
                            onChanged: (t) {
                              if (t != null) setState(() => _customTime = t);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. [홈 화면 위젯 즉시 동기화] 액션 버튼
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                _isSyncing ? '위젯 동기화 중...' : '3종 위젯(4x2, 4x4, 4x6) 홈 화면에 즉시 동기화',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _isSyncing ? null : _syncToHomeWidget,
            ),
          ),
        ],
      ),
    );
  }
}

