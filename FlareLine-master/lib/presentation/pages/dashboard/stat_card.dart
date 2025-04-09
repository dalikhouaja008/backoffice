import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline/core/theme/global_colors.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String percentage;
  final bool isGrow;

  const StatCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.percentage,
    required this.isGrow, required color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      height: 166,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: Icon(
                  icon,
                  color: GlobalColors.sideBar,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey
                  ),
                ),
                const Spacer(),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 10,
                    color: isGrow ? Colors.green : Colors.red
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  isGrow ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isGrow ? Colors.green : Colors.red,
                  size: 12,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}