import 'package:flutter/material.dart';

import '../models/schedule_color.dart';

class ScheduleColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ScheduleColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(ScheduleColor.colors.length, (index) {
        final selected = selectedIndex == index;

        return Tooltip(
          message: ScheduleColor.names[index],
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => onChanged(index),
            child: Semantics(
              label: '${ScheduleColor.names[index]} 색상',
              selected: selected,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ScheduleColor.colors[index],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
