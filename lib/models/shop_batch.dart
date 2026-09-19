class ShopBatch {
  final int batchId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String batchTypeName;
  final int stepsToComplete;
  final int stepsInProgress;
  final int stepsCompleted;
  final int stepsTotal;

  const ShopBatch({
    required this.batchId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.batchTypeName,
    required this.stepsToComplete,
    required this.stepsInProgress,
    required this.stepsCompleted,
    required this.stepsTotal,
  });

  bool get isComplete {
    final statusKey = status.toLowerCase();
    if (statusKey == 'completed') return true;
    return stepsTotal > 0 && stepsCompleted >= stepsTotal;
  }

  double get completionPercentage =>
      stepsTotal == 0 ? 0 : stepsCompleted / stepsTotal * 100;

  String get expectedAvailabilityLabel {
    if (endDate.isBefore(startDate)) return 'Date to be confirmed';
    return _format(endDate);
  }

  static String _format(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
