import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/widget_service.dart';
import '../stores/schedule_store.dart';
import '../widgets/calendar_import_sheet.dart';
import 'calendar_screen.dart';
import 'day_screen.dart';
import 'shift_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final ScheduleStore _scheduleStore = ScheduleStore();
  bool _hasPromptedSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoSyncWidgets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasPromptedSync && mounted) {
        _hasPromptedSync = true;
        _showInitialSyncDialog();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduleStore.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _autoSyncWidgets();
    }
  }

  void _autoSyncWidgets() {
    WidgetService.syncAllWidgets(store: _scheduleStore);
  }

  void _showInitialSyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Color(0xFF007AFF)),
            SizedBox(width: 8),
            Text(
              '캘린더 일정 동기화',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          '스마트폰(Google, Apple 캘린더)에 등록된 기존 일정을 앱으로 한 번에 가져오시겠습니까?\n\n* 우측 상단 [설정] 메뉴에서도 언제든 다시 가져올 수 있습니다.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('나중에', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              CalendarImportSheet.show(context, _scheduleStore);
            },
            child: const Text('지금 가져오기'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screens = [
      CalendarScreen(store: _scheduleStore),
      DayScreen(store: _scheduleStore),
      ShiftScreen(store: _scheduleStore),
    ];

    return Scaffold(
      extendBody: true, // 하단 리퀴드 글래스 뒤로 콘텐츠 투과
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text(
          'All-in-One Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.5,
            color: Color(0xFF1C1C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1C1C1E)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(store: _scheduleStore),
                ),
              );
            },
          ),
        ],
      ),

      body: IndexedStack(index: _selectedIndex, children: screens),

      // iOS 18 스타일 플로팅 리퀴드 글래스 캡슐 탭 바 (liquid_glass_widgets GlassContainer)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: GlassContainer(
            useOwnLayer: true,
            height: 64,
            settings: LiquidGlassSettings.ios27Light,
            shape: const LiquidRoundedSuperellipse(borderRadius: 32),
            color: Colors.white.withValues(alpha: 0.65),
            glowIntensity: 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLiquidTab(
                  index: 0,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: '캘린더',
                ),
                _buildLiquidTab(
                  index: 1,
                  icon: Icons.schedule_outlined,
                  activeIcon: Icons.schedule,
                  label: '하루',
                ),
                _buildLiquidTab(
                  index: 2,
                  icon: Icons.work_outline,
                  activeIcon: Icons.work,
                  label: '근무표',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidTab({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // 테두리 없는 맑은 리퀴드 글래스 수분감 틴트
          color: isSelected
              ? const Color(0xFF007AFF).withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
