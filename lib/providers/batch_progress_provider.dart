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
    return _batches.where((batch) => !batch.isComplete).toList()
      ..sort((a, b) => a.batchId.compareTo(b.batchId));
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
      final next = <ShopBatch>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final status = (data['status'] ?? 'unknown').toString();
          if (status.toLowerCase() == 'completed' ||
              status.toLowerCase() == 'cancelled' ||
              status.toLowerCase() == 'canceled') {
            continue;
          }

          final batchId = data['batchId'] ?? 0;
          final counts = await _stepCounts(batchId.toString());
          if (counts.total > 0 && counts.completed >= counts.total) {
            continue;
          }

          final typeId = (data['batchTypeId'] ?? 'biltong').toString();
          next.add(
            ShopBatch(
              batchId: batchId is int
                  ? batchId
                  : int.tryParse(batchId.toString()) ?? 0,
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

  Future<_StepCounts> _stepCounts(String batchId) async {
    final snapshot = await _db
        .collection('batch_step_instances')
        .where('batchId', isEqualTo: batchId)
        .get();

    var toComplete = 0;
    var inProgress = 0;
    var completed = 0;

    for (final doc in snapshot.docs) {
      final key = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
      if (key == 'completed') {
        completed++;
      } else if (key == 'in progress' ||
          key == 'in_progress' ||
          key == 'started' ||
          key == 'processing') {
        inProgress++;
      } else {
        toComplete++;
      }
    }

    return _StepCounts(
      toComplete: toComplete,
      inProgress: inProgress,
      completed: completed,
      total: snapshot.docs.length,
    );
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
    required this.toComplete,
    required this.inProgress,
    required this.completed,
    required this.total,
  });
}
