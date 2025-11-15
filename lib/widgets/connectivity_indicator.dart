import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/log_providers.dart';
import '../services/sync_service.dart';

class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        // Don't show any indicator when there's no user
        if (status == SyncStatus.noUser) {
          return const SizedBox.shrink();
        }

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
          case SyncStatus.noUser:
            // This case is handled above, but needed for exhaustive switch
            return const SizedBox.shrink();
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
