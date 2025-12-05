import 'package:flutter/material.dart';
import 'package:marcket_app/widgets/shimmer_loading.dart';

class PublicationCardSkeleton extends StatelessWidget {
  const PublicationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerLoading.circular(width: 40, height: 40),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoading.rectangular(height: 16, width: 150),
                    const SizedBox(height: 4),
                    ShimmerLoading.rectangular(height: 12, width: 100),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerLoading.rectangular(height: 200),
            const SizedBox(height: 12),
            const ShimmerLoading.rectangular(height: 14, width: 250),
            const SizedBox(height: 8),
            const ShimmerLoading.rectangular(height: 14, width: 200),
          ],
        ),
      ),
    );
  }
}
