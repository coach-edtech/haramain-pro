import 'package:flutter/material.dart';
import 'package:haramain_pro/features/virtual_muthawif/data/doa_repository.dart';

class PrayerCard extends StatelessWidget {
  final String zoneId;
  final bool compact;

  const PrayerCard({
    super.key,
    required this.zoneId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final doaData = DoaRepository.instance.getDoaData(zoneId);
    
    if (doaData == null) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactCard(context, doaData);
    }
    return _buildFullCard(context, doaData);
  }

  Widget _buildCompactCard(BuildContext context, Map<String, dynamic> doaData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  doaData['name'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              doaData['indonesian'] as String? ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context, Map<String, dynamic> doaData) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  doaData['arabic'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  doaData['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (doaData['description'] != null) ...[
                  Text(
                    doaData['description'] as String,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Transliteration
                if (doaData['latin'] != null) ...[
                  const Text(
                    'Transliterasi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doaData['latin'] as String,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Indonesian translation
                if (doaData['indonesian'] != null) ...[
                  const Text(
                    'Arti:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doaData['indonesian'] as String,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ],
            ),
          ),

          // Share button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () {
                // Share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Doa'),
            ),
          ),
        ],
      ),
    );
  }
}
