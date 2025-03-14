import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';

class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        IconData icon;
        Color color;
        String message;

        switch (status) {
          case SyncStatus.syncing:
            icon = Icons.sync;
            color = Colors.amber;
            message = 'Syncing...';
            break;
          case SyncStatus.synced:
            icon = Icons.cloud_done;
            color = Colors.green;
            message = 'All changes synced';
            break;
          case SyncStatus.offline:
            icon = Icons.cloud_off;
            color = Colors.grey;
            message = 'Working offline';
            break;
          case SyncStatus.error:
            icon = Icons.sync_problem;
            color = Colors.red;
            message = 'Sync error';
            break;
        }

        return Tooltip(
          message: message,
          child: Icon(icon, color: color),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Icon(Icons.warning, color: Colors.red),
    );
  }
}
