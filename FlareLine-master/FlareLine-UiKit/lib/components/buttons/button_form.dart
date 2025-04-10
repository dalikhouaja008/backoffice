import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

enum ButtonType {
  normal('normal'),
  primary('primary'),
  success('success'),
  info('info'),
  warn('warn'),
  danger('danger'),
  dark('dark');

  const ButtonType(this.type);

  final String type;
}

class ButtonForm extends StatelessWidget {
  final String btnText;
  final VoidCallback? onPressed;
  final Color? color;
  final double? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final Color? textColor;
  final Widget? iconWidget;
  final String? type;
  final double? height;
  final double? fontSize;
  final bool isLoading;

  const ButtonForm({
    required this.btnText,
    this.onPressed,
    this.color,
    this.borderRadius,
    this.borderColor,
    this.textColor,
    this.iconWidget,
    this.type,
    this.borderWidth,
    this.height,
    this.fontSize,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
        child: Container(
          width: double.maxFinite,
          height: height ?? 48,
          alignment: Alignment.center,
          decoration: buildBoxDecoration(context),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconWidget != null) iconWidget!,
                    if (iconWidget != null && btnText.isNotEmpty)
                      const SizedBox(width: 8),
                    if (btnText.isNotEmpty)
                      Text(
                        btnText,
                        style: TextStyle(
                          color: textColor ?? 
                              (type != null ? Colors.white : ButtonColors.normal),
                          fontSize: fontSize ?? 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  BoxDecoration buildBoxDecoration(BuildContext context) {
    final Color buttonColor = color ?? getTypeColor(type);
    
    return BoxDecoration(
      border: borderColor != null
          ? Border.all(color: borderColor!, width: borderWidth ?? 1)
          : (type == null
              ? Border.all(color: ButtonColors.normal, width: 1)
              : null),
      color: isLoading ? buttonColor.withOpacity(0.7) : buttonColor,
      borderRadius: BorderRadius.circular(borderRadius ?? 4),
    );
  }

  Color getTypeColor(String? type) {
    switch (type) {
      case 'primary':
        return ButtonColors.primary;
      case 'success':
        return ButtonColors.success;
      case 'info':
        return ButtonColors.info;
      case 'warn':
        return ButtonColors.warn;
      case 'danger':
        return ButtonColors.danger;
      case 'dark':
        return ButtonColors.dark;
      default:
        return Colors.white;
    }
  }
}