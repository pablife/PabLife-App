import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  AppSnackbar._();
  
  static AppSnackbar get to => AppSnackbar._();
  
  void show(String message, {Widget? mainButton}) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(10),
      borderRadius: 8.0,
      snackPosition: SnackPosition.BOTTOM,
      mainButton: mainButton ?? TextButton(
        onPressed: Get.back,
        child: const Text('OK', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
