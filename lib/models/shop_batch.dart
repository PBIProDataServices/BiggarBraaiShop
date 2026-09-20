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

  String get _statusKey =>
      status.toLowerCase().trim().replaceAll(' ', '_');

  bool get isClosed {
    return _statusKey == 'completed' ||
        _statusKey == 'closed' ||
        _statusKey == 'cancelled' ||
        _statusKey == 'canceled' ||
        _statusKey == 'done';
  }

  bool get isComplete {
    if (isClosed) return true;
    return stepsTotal > 0 && stepsCompleted >= stepsTotal;
  }

  bool get isUpcoming => !isComplete;

  String get statusLabel {
    switch (_statusKey) {
      case 'in_progress':
        return 'In progress';
      case 'pending':
      case 'planned':
      case 'upcoming':
        return 'Coming up';
      default:
        return status.isEmpty ? 'Coming up' : status;
    }
  }

  int get sortRank {
    switch (_statusKey) {
      case 'in_progress':
        return 0;
      case 'pending':
      case 'planned':
      case 'upcoming':
        return 1;
      default:
        return 2;
    }
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
