import 'package:flutter/material.dart';

class SyncStatusBar extends StatelessWidget {
  final int pendingCount;
  final int syncedCount;
  final VoidCallback? onSync;

  const SyncStatusBar({
    super.key,
    required this.pendingCount,
    required this.syncedCount,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final total = pendingCount + syncedCount;
    final syncProgress = total > 0 ? syncedCount / total : 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Row(
        children: [
          // Sync icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sync,
              size: 20,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pendingCount photos pending sync',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: syncProgress,
                    backgroundColor: Colors.blue[200],
                    valueColor: AlwaysStoppedAnimation(Colors.blue[700]),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$syncedCount of $total photos backed up',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),

          // Sync button
          if (pendingCount > 0)
            TextButton(
              onPressed: onSync,
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }
}
