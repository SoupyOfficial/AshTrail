import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        switch (status) {
          case SyncStatus.syncing:
            return const Tooltip(
              message: 'Syncing with server...',
              child: Icon(Icons.sync, color: Colors.amber),
            );
          case SyncStatus.synced:
            return const Tooltip(
              message: 'All changes synced',
              child: Icon(Icons.cloud_done, color: Colors.green),
            );
          case SyncStatus.offline:
            return const Tooltip(
              message:
                  'You\'re offline. Changes will sync when connection returns',
              child: Icon(Icons.cloud_off, color: Colors.grey),
            );
          case SyncStatus.error:
            return const Tooltip(
              message: 'Sync error. Will retry automatically',
              child: Icon(Icons.sync_problem, color: Colors.red),
            );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Icon(Icons.warning, color: Colors.red),
    );
  }
}
