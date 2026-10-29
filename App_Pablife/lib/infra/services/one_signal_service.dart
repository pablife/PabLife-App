import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OneSignalService {
  static const String _oneSignalAppId = 'ccef00af-323d-4e75-8957-0fca60659b73';
  static const String _oneSignalRestApiKey = String.fromEnvironment(
    'ONESIGNAL_REST_API_KEY',
  );
  static const String _oneSignalUrl =
      'https://onesignal.com/api/v1/notifications?c=push';

  static Future<bool> scheduleNotification({
    required String title,
    required String message,
    required String? oneSignalUserId,
    required DateTime sendAfter,
  }) async {
    // Cannot send notification without a valid OneSignal user ID
    if (oneSignalUserId == null || oneSignalUserId.isEmpty) {
      debugPrint('⚠️ [OneSignalService] Cannot schedule notification: oneSignalUserId is null or empty');
      return false;
    }

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic $_oneSignalRestApiKey',
    };

    final body = {
      'app_id': _oneSignalAppId,
      'include_subscription_ids': [oneSignalUserId],
      'headings': {'en': title},
      'contents': {'en': message},
      'priority': 10,
      'send_after': sendAfter.toIso8601String(),
      'small_icon': 'ic_notification_small',
    };

    final response = await http.post(
      Uri.parse(_oneSignalUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ [OneSignalService] Notification scheduled successfully: ${responseData['id']}');
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      debugPrint('❌ [OneSignalService] Failed to schedule notification');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Error: ${errorData['errors']}');

      // Check if user is not subscribed
      if (errorData['errors']?.toString().contains('not subscribed') == true) {
        debugPrint('   ⚠️ User is not subscribed to push notifications');
      }

      return false;
    }
  }
}
