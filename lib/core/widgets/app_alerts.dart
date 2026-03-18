import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppAlerts {
  // Note: Colors.white is intentionally used here since Get.snackbar
  // doesn't have access to BuildContext for theme colors
  // White provides good contrast on error/success colored backgrounds
  static void showError(String message, {String title = 'Error'}) {
    if (message.isEmpty) return;
    
    // Format the message to be more professional
    final formattedMessage = _formatErrorMessage(message);
    final errorTitle = _getErrorTitle(message);
    
    Get.snackbar(
      errorTitle,
      formattedMessage,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.error,
      colorText: Colors.white, // White for good contrast on error red
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      duration: const Duration(seconds: 5),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: AppColors.error.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ],
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      mainButton: TextButton(
        onPressed: () => Get.back(),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        child: const Text(
          'Got it',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      snackStyle: SnackStyle.FLOATING,
      maxWidth: 500,
    );
  }
  
  /// Get appropriate title based on error type
  static String _getErrorTitle(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('too many') || lowerMessage.contains('429')) {
      return 'Rate Limit Exceeded';
    }
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Connection Error';
    }
    if (lowerMessage.contains('timeout')) {
      return 'Request Timeout';
    }
    if (lowerMessage.contains('server') || lowerMessage.contains('500')) {
      return 'Server Error';
    }
    if (lowerMessage.contains('unauthorized') || lowerMessage.contains('401')) {
      return 'Authentication Failed';
    }
    if (lowerMessage.contains('forbidden') || lowerMessage.contains('403')) {
      return 'Access Denied';
    }
    if (lowerMessage.contains('not found') || lowerMessage.contains('404')) {
      return 'Not Found';
    }
    
    return 'Error';
  }

  static void showSuccess(String message, {String title = 'Success'}) {
    if (message.isEmpty) return;
    
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      duration: const Duration(seconds: 3),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: AppColors.success.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ],
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      snackStyle: SnackStyle.FLOATING,
      maxWidth: 500,
    );
  }

  static void showWarning(String message, {String title = 'Warning'}) {
    if (message.isEmpty) return;
    
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.warning,
      colorText: Colors.white,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      duration: const Duration(seconds: 4),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: AppColors.warning.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ],
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      snackStyle: SnackStyle.FLOATING,
      maxWidth: 500,
    );
  }

  static void showInfo(String message, {String title = 'Information'}) {
    if (message.isEmpty) return;
    
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.info,
      colorText: Colors.white,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      duration: const Duration(seconds: 3),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.info_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: AppColors.info.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ],
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      snackStyle: SnackStyle.FLOATING,
      maxWidth: 500,
    );
  }

  /// Format error messages to be more user-friendly
  static String _formatErrorMessage(String message) {
    // Common error patterns and their user-friendly versions
    final Map<RegExp, String> errorMappings = {
      RegExp(r'invalid.*email', caseSensitive: false): 
          'Please enter a valid email address.',
      RegExp(r'email.*not.*found', caseSensitive: false): 
          'This email address is not registered. Please check and try again.',
      RegExp(r'invalid.*credentials', caseSensitive: false): 
          'The email or password you entered is incorrect.',
      RegExp(r'invalid.*otp|otp.*invalid', caseSensitive: false): 
          'The verification code you entered is invalid. Please try again.',
      RegExp(r'otp.*expired', caseSensitive: false): 
          'Your verification code has expired. Please request a new one.',
      RegExp(r'user.*not.*found', caseSensitive: false): 
          'Account not found. Please check your credentials.',
      RegExp(r'password.*weak|weak.*password', caseSensitive: false): 
          'Please choose a stronger password with at least 8 characters.',
      RegExp(r'email.*already.*exists|email.*taken', caseSensitive: false): 
          'This email address is already registered. Please use another email or try logging in.',
      RegExp(r'network.*error|connection.*failed', caseSensitive: false): 
          'Unable to connect to the server. Please check your internet connection.',
      RegExp(r'timeout', caseSensitive: false): 
          'The request timed out. Please try again.',
      RegExp(r'unauthorized|not.*authorized', caseSensitive: false): 
          'You do not have permission to perform this action.',
      RegExp(r'session.*expired', caseSensitive: false): 
          'Your session has expired. Please log in again.',
      RegExp(r'account.*locked|locked.*account', caseSensitive: false): 
          'Your account has been temporarily locked. Please contact support.',
      RegExp(r'too.*many.*requests', caseSensitive: false): 
          'Too many attempts. Please wait a moment and try again.',
      RegExp(r'server.*error|internal.*error', caseSensitive: false): 
          'A server error occurred. Please try again later.',
    };

    // Check if message matches any known patterns
    for (final entry in errorMappings.entries) {
      if (entry.key.hasMatch(message)) {
        return entry.value;
      }
    }

    // If no pattern matches, capitalize first letter and ensure it ends with a period
    final formattedMessage = message.trim();
    if (formattedMessage.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }
    
    final capitalized = formattedMessage[0].toUpperCase() + 
        formattedMessage.substring(1);
    
    return capitalized.endsWith('.') || capitalized.endsWith('!') || capitalized.endsWith('?')
        ? capitalized
        : '$capitalized.';
  }
}


