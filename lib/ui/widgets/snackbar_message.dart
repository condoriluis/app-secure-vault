import 'package:flutter/material.dart';

void showCustomSnackBar(
  BuildContext context,
  String message, {
  int durationSeconds = 2,
  Color? backgroundColor,
}) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final theme = Theme.of(context);

  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/logo.png', width: 24, height: 24),
          const SizedBox(width: 8),
          Flexible(child: Text(message, overflow: TextOverflow.fade)),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      duration: Duration(seconds: durationSeconds),
    ),
  );

  Future.delayed(Duration(seconds: durationSeconds), () {
    if (scaffoldMessenger.mounted) {
      scaffoldMessenger.hideCurrentSnackBar();
    }
  });
}
