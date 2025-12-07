import 'package:flutter/material.dart';
import 'package:marcket_app/widgets/shimmer_loading.dart';

class PublicationCardSkeleton extends StatelessWidget {
  const PublicationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                                children: [                ShimmerLoading.circular(width: 40, height: 40),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    ShimmerLoading.rectangular(height: 16, width: 150),
                    SizedBox(height: 4),
                    ShimmerLoading.rectangular(height: 12, width: 100),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            ShimmerLoading.rectangular(height: 200),
            SizedBox(height: 12),
            ShimmerLoading.rectangular(height: 14, width: 250),
            SizedBox(height: 8),
            ShimmerLoading.rectangular(height: 14, width: 200),
          ],
        ),
      ),
    );
  }
}
