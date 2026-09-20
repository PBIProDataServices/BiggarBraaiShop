import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../consts/firebase_consts.dart';
import '../../models/shop_batch.dart';
import '../../providers/batch_progress_provider.dart';
import '../../screens/auth/login.dart';
import '../../screens/auth/register.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';

class BatchesScreen extends StatefulWidget {
  static const routeName = '/Batches';
  const BatchesScreen({Key? key}) : super(key: key);

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authInstance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isSignedIn = user != null && !user.isAnonymous;
        if (!isSignedIn) {
          return const _SignInToSeeBatches();
        }
        return const _BatchList();
      },
    );
  }
}

class _SignInToSeeBatches extends StatelessWidget {
  const _SignInToSeeBatches();

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Batch progress',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: color.withOpacity(0.6)),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Sign in to follow batches',
              color: color,
              textSize: 22,
              isTitle: true,
            ),
            const SizedBox(height: 12),
            Text(
              'See overall progress on current batches, and when stock is likely to become available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Utils(context).secondaryColor, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(LoginScreen.routeName);
              },
              child: const Text('Sign in'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(RegisterScreen.routeName);
              },
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchList extends StatefulWidget {
  const _BatchList();

  @override
  State<_BatchList> createState() => _BatchListState();
}

class _BatchListState extends State<_BatchList> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BatchProgressProvider>(context, listen: false).fetchBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BatchProgressProvider>(context);
    final color = Utils(context).color;
    final batches = provider.currentBatches;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Batch progress',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.fetchBatches,
              child: batches.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.timelapse,
                            size: 64, color: color.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            provider.error ??
                                'No upcoming batches right now.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: batches.length,
                      itemBuilder: (context, index) {
                        return _BatchSummaryCard(
                          batch: batches[index],
                          color: color,
                        );
                      },
                    ),
            ),
    );
  }
}

class _BatchSummaryCard extends StatelessWidget {
  const _BatchSummaryCard({required this.batch, required this.color});

  final ShopBatch batch;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextWidget(
                    text: '${batch.batchTypeName}  #${batch.batchId}',
                    color: color,
                    textSize: 18,
                    isTitle: true,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: batch.statusLabel == 'In progress'
                        ? Colors.orange.withOpacity(0.16)
                        : Colors.blue.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    batch.statusLabel,
                    style: TextStyle(
                      color: batch.statusLabel == 'In progress'
                          ? Colors.orange[800]
                          : Colors.blue[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              minHeight: 8,
              value: (batch.completionPercentage / 100).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            Text(
              '${batch.completionPercentage.round()}% complete',
              style: TextStyle(color: color.withOpacity(0.85)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CountChip(
                    label: 'To complete',
                    count: batch.stepsToComplete,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountChip(
                    label: 'In progress',
                    count: batch.stepsInProgress,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountChip(
                    label: 'Completed',
                    count: batch.stepsCompleted,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Likely available from ${batch.expectedAvailabilityLabel}',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
