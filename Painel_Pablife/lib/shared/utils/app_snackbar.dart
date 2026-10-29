import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';

class AppSnackbar {
  AppSnackbar._();

  static AppSnackbar get to => AppSnackbar._();

  /// Safely shows a snackbar using ScaffoldMessenger (more stable than Get.snackbar)
  void _safeShowSnackbar({
    required String message,
    required Color backgroundColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    // Get the root scaffold messenger key from GetMaterialApp
    final context = Get.context;
    if (context == null) {
      debugPrint('AppSnackbar: No context available, skipping snackbar');
      return;
    }

    try {
      // Clear any existing snackbars first
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: action,
        ),
      );
    } catch (e) {
      debugPrint('AppSnackbar: Failed to show snackbar - $e');
    }
  }

  void show(String message, {VoidCallback? onAction}) {
    _safeShowSnackbar(
      message: message,
      backgroundColor: AppColors.info,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        textColor: AppColors.white,
        onPressed: onAction ?? () {},
      ),
    );
  }

  void success(String message) {
    _safeShowSnackbar(
      message: message,
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 3),
    );
  }

  void error(String message) {
    _safeShowSnackbar(
      message: message,
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 5),
    );
  }

  void warning(String message) {
    _safeShowSnackbar(
      message: message,
      backgroundColor: AppColors.warning,
      duration: const Duration(seconds: 4),
    );
  }
}
