import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../network/api_exception.dart';
import '../theme/app_theme.dart';

class SnackbarUtils {
  /// Returns true when an error is a network/connectivity failure.
  /// Use this in catch blocks to silently swallow no-internet errors —
  /// the ApiClient interceptor already shows a single global banner.
  static bool isNoInternet(Object e) {
    if (e is NoInternetException) return true;
    if (e is DioException && e.error is NoInternetException) return true;
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('nointernetexception');
  }

  static void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      icon: const Icon(
        Icons.check_circle_rounded,
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: true,
      boxShadows: [
        BoxShadow(
          color: AppTheme.successColor.withValues(alpha: 0.3),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.errorColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      icon: const Icon(Icons.error_rounded, color: Colors.white, size: 28),
      shouldIconPulse: true,
      boxShadows: [
        BoxShadow(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static void showInfo(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.info,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      icon: const Icon(Icons.info_rounded, color: Colors.white, size: 28),
      shouldIconPulse: true,
      boxShadows: [
        BoxShadow(
          color: AppTheme.info.withValues(alpha: 0.3),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static void showWarning(String message) {
    Get.snackbar(
      'Warning',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppTheme.warning,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      icon: const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
      shouldIconPulse: true,
      boxShadows: [
        BoxShadow(
          color: AppTheme.warning.withValues(alpha: 0.3),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static void showCustom({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: textColor,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      icon: Icon(icon, color: textColor, size: 28),
      shouldIconPulse: true,
      boxShadows: [
        BoxShadow(
          color: backgroundColor.withValues(alpha: 0.3),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Fallback method using ScaffoldMessenger
  static void showErrorFallback(String message) {
    print('🚨 Using fallback snackbar for: $message');
    try {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        print('🚨 Fallback snackbar displayed');
      } else {
        print('🚨 No context available for fallback snackbar');
      }
    } catch (e) {
      print('🚨 Fallback snackbar also failed: $e');
    }
  }

  static void showSuccessFallback(String message) {
    print('🎉 Using fallback success snackbar for: $message');
    try {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        print('🎉 Fallback success snackbar displayed');
      } else {
        print('🎉 No context available for fallback snackbar');
      }
    } catch (e) {
      print('🎉 Fallback success snackbar also failed: $e');
    }
  }
}
