import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;
  final String? progressLabel;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.progress = 0.0,
    this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              if (progress != 0.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: progress > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        progress > 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: progress > 0 ? Colors.green : Colors.red,
                      ),
                      const Gap(2),
                      Text(
                        '${(progress * 100).abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: progress > 0 ? Colors.green : Colors.red,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontFamily: 'Cairo',
            ),
          ),
          if (progressLabel != null) ...[
            const Gap(8),
            LinearProgressIndicator(
              value: progress.abs(),
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 4,
            ),
            const Gap(4),
            Text(
              progressLabel!,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.6),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> stats;

  const StatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return StatsCard(
          title: stat['title'],
          value: stat['value'],
          icon: stat['icon'],
          color: stat['color'],
          progress: stat['progress'] ?? 0.0,
          progressLabel: stat['progressLabel'],
        );
      },
    );
  }
}
