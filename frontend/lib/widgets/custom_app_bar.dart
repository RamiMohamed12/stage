import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color foregroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor = AppColors.primaryColor,
    this.foregroundColor = AppColors.whiteColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: TextStyle(color: foregroundColor)),
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: foregroundColor),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
