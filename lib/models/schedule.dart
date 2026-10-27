class Schedule {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int colorIndex;
  final bool isShift;
  final String? shiftTypeId;

  const Schedule({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.colorIndex = 0,
    this.isShift = false,
    this.shiftTypeId,
  });
}
