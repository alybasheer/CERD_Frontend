import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fyp_source_code/network/friendly_error.dart';
import 'package:get/get.dart';
/// Professional generic toast messages for common scenarios
class ToastMessages {
  // ============ SERVER MESSAGES ============
  static String get serverError => 'toast.server_error'.tr;
  static String get networkError => 'toast.network_error'.tr;
  static String get timeoutError => 'toast.timeout_error'.tr;
  static String get invalidInput => 'toast.invalid_input'.tr;
  static String get sessionExpired => 'toast.session_expired'.tr;
  static String get notFound => 'toast.not_found'.tr;
  static String get conflict => 'toast.conflict'.tr;
}

enum _ToastType { success, error, warning, info }

/// Toast utility for showing app-styled snackbars and notifications.
class ToastHelper {
  static const double _maxSnackWidth = 420;

  static void showSuccess(String message) {
    _show(message, _ToastType.success);
  }

  static void showError(String message) {
    _show(message, _ToastType.error);
  }

  static void showWarning(String message) {
    _show(message, _ToastType.warning);
  }

  static void showInfo(String message) {
    _show(message, _ToastType.info);
  }

  static void showCustom(
    String message, {
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    Toast toastLength = Toast.LENGTH_SHORT,
    int timeInSecForIosWeb = 2,
  }) {
    _show(
      message,
      _ToastType.info,
      backgroundColor: backgroundColor,
      textColor: textColor,
      duration: Duration(seconds: timeInSecForIosWeb),
    );
  }

  static void cancelAll() {
    Fluttertoast.cancel();
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  // ============ GENERIC PROFESSIONAL MESSAGES ============

  /// Show generic error - extracts and formats API errors professionally
  static void showErrorMessage(dynamic error) {
    showError(friendlyErrorMessage(error));
  }

  static void _show(
    String message,
    _ToastType type, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final config = _ToastConfig.fromType(type);
    final bgColor = backgroundColor ?? config.backgroundColor;
    final fgColor = textColor ?? config.foregroundColor;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      messageText: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fgColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
      icon: Icon(config.icon, color: fgColor, size: 22),
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      maxWidth: _maxSnackWidth,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      backgroundColor: bgColor,
      leftBarIndicatorColor: config.accentColor,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      duration: duration,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      animationDuration: const Duration(milliseconds: 220),
      shouldIconPulse: false,
    );
  }
}

class _ToastConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;
  final IconData icon;

  const _ToastConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
    required this.icon,
  });

  factory _ToastConfig.fromType(_ToastType type) {
    switch (type) {
      case _ToastType.success:
        return const _ToastConfig(
          backgroundColor: Color(0xFF0F766E),
          foregroundColor: Colors.white,
          accentColor: Color(0xFF5EEAD4),
          icon: Icons.check_circle_rounded,
        );
      case _ToastType.error:
        return const _ToastConfig(
          backgroundColor: Color(0xFFB91C1C),
          foregroundColor: Colors.white,
          accentColor: Color(0xFFFCA5A5),
          icon: Icons.error_rounded,
        );
      case _ToastType.warning:
        return const _ToastConfig(
          backgroundColor: Color(0xFFB45309),
          foregroundColor: Colors.white,
          accentColor: Color(0xFFFCD34D),
          icon: Icons.warning_rounded,
        );
      case _ToastType.info:
        return const _ToastConfig(
          backgroundColor: Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          accentColor: Color(0xFF93C5FD),
          icon: Icons.info_rounded,
        );
    }
  }
}
