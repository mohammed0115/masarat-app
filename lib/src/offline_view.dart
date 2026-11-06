import 'package:flutter/material.dart';

import 'theme.dart';

/// Shown instead of the browser's error page when the school server cannot be reached.
class OfflineView extends StatelessWidget {
  const OfflineView({super.key, required this.onRetry, this.detail});

  final VoidCallback onRetry;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Brand.blue),
          const SizedBox(height: 20),
          const Text(
            'تعذّر الاتصال بالمدرسة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Brand.navy),
          ),
          const SizedBox(height: 10),
          const Text(
            'تحقّق من اتصالك بالإنترنت ثم أعد المحاولة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Brand.muted, height: 1.6),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Brand.muted),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: FilledButton.styleFrom(
              backgroundColor: Brand.navy,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
