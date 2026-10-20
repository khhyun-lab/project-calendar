import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeInput extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay?> onChanged;

  const TimeInput({
    super.key,
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<TimeInput> {
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;

  bool _isValid = true;

  @override
  void initState() {
    super.initState();

    _hourController = TextEditingController(
      text: widget.initialTime.hour.toString().padLeft(2, '0'),
    );

    _minuteController = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
  }

  void _updateTime() {
    final hour = int.tryParse(_hourController.text);
    final minute = int.tryParse(_minuteController.text);

    final valid =
        hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;

    setState(() {
      _isValid = valid;
    });

    if (!valid) {
      widget.onChanged(null);
      return;
    }

    widget.onChanged(TimeOfDay(hour: hour, minute: minute));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 58,
              child: TextField(
                controller: _hourController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  hintText: '시',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => _updateTime(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(':', style: TextStyle(fontSize: 22)),
            ),
            SizedBox(
              width: 58,
              child: TextField(
                controller: _minuteController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  hintText: '분',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => _updateTime(),
              ),
            ),
          ],
        ),
        if (!_isValid)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '시간을 확인하세요.',
              style: TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
