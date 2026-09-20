import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../consts/firebase_consts.dart';
import '../models/shop_batch.dart';

class BatchProgressProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ShopBatch> _batches = [];
  Map<String, String> _batchTypeNames = {};
  bool _isLoading = false;
  String? _error;

  List<ShopBatch> get batches => _batches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ShopBatch> get currentBatches {
    final upcoming = _batches.where((batch) => batch.isUpcoming).toList();
    upcoming.sort((a, b) {
      final statusOrder = a.sortRank.compareTo(b.sortRank);
      if (statusOrder != 0) return statusOrder;
      final dateOrder = a.endDate.compareTo(b.endDate);
      if (dateOrder != 0) return dateOrder;
      return a.batchId.compareTo(b.batchId);
    });
    return upcoming;
  }

  Future<void> fetchBatches() async {
    final user = authInstance.currentUser;
    if (user == null || user.isAnonymous) {
      _batches = [];
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadBatchTypes();
      final snapshot = await _db.collection('batch').get();
      final stepCounts = await _loadAllStepCounts();
      final next = <ShopBatch>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final batchId = _parseBatchId(data['batchId'] ?? doc.id);
          final counts = stepCounts[batchId.toString()] ?? const _StepCounts();
          final status = (data['status'] ?? 'pending').toString();
          final typeId = (data['batchTypeId'] ?? 'biltong').toString();

          next.add(
            ShopBatch(
              batchId: batchId,
              status: status,
              startDate: _toDate(data['startDate']) ?? DateTime.now(),
              endDate: _toDate(data['endDate']) ??
                  DateTime.now().add(const Duration(days: 7)),
              batchTypeName: _batchTypeNames[typeId] ?? _titleCase(typeId),
              stepsToComplete: counts.toComplete,
              stepsInProgress: counts.inProgress,
              stepsCompleted: counts.completed,
              stepsTotal: counts.total,
            ),
          );
        } catch (error) {
          debugPrint('Skipping batch ${doc.id}: $error');
        }
      }

      _batches = next;
    } catch (error) {
      _error = error.toString();
      _batches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBatchTypes() async {
    try {
      final snapshot = await _db.collection('batch_types').get();
      _batchTypeNames = {
        for (final doc in snapshot.docs)
          doc.id: (doc.data()['name'] ?? doc.id).toString(),
      };
    } catch (error) {
      debugPrint('Batch types not readable: $error');
      _batchTypeNames = {};
    }
  }

  Future<Map<String, _StepCounts>> _loadAllStepCounts() async {
    try {
      final snapshot = await _db.collection('batch_step_instances').get();
      final grouped = <String, List<String>>{};

      for (final doc in snapshot.docs) {
        final key = (doc.data()['batchId'] ?? '').toString();
        if (key.isEmpty) continue;
        grouped.putIfAbsent(key, () => []).add(
              (doc.data()['status'] ?? 'pending').toString().toLowerCase(),
            );
      }

      return grouped.map((key, statuses) {
        var toComplete = 0;
        var inProgress = 0;
        var completed = 0;
        for (final status in statuses) {
          if (status == 'completed' || status == 'closed' || status == 'done') {
            completed++;
          } else if (status == 'in progress' ||
              status == 'in_progress' ||
              status == 'started' ||
              status == 'processing') {
            inProgress++;
          } else {
            toComplete++;
          }
        }
        return MapEntry(
          key,
          _StepCounts(
            toComplete: toComplete,
            inProgress: inProgress,
            completed: completed,
            total: statuses.length,
          ),
        );
      });
    } catch (error) {
      debugPrint('Step instances not readable: $error');
      return {};
    }
  }

  int _parseBatchId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _StepCounts {
  final int toComplete;
  final int inProgress;
  final int completed;
  final int total;

  const _StepCounts({
    this.toComplete = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.total = 0,
  });
}
