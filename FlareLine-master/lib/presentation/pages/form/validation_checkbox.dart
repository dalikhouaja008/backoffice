import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline_uikit/components/forms/checkbox_widget.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ValidationCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final Function(bool?) onChanged;
  final Color? checkColor;
  final double? size;

  const ValidationCheckbox({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.checkColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final logger = Logger();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: CheckBoxWidget(
        checked: value,
        text: label,
        checkedColor: checkColor ?? GlobalColors.primary,
        size: size ?? 24,
        value: label,
        onChanged: (checked, _) {
          onChanged(checked);
          
          logger.log(
            Level.info,
            'Validation checkbox state changed',
            error: {
              'value': checked,
              'label': label,
              'timestamp': '2025-04-09 21:43:21',
              'userLogin': 'dalikhouaja008'
            },
          );
        },
      ),
    );
  }
}