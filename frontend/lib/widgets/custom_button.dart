import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.primaryColor,
    this.textColor = AppColors.whiteColor,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: textColor, size: 20),
            if (icon != null && text.isNotEmpty)
              const SizedBox(width: 8),
            if (text.isNotEmpty)
              Text(text, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}
