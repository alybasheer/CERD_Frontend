import 'package:dio/dio.dart';
import 'package:fyp_source_code/network/exceptions.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';

/// Maps low-level exceptions and technical backend strings to plain, friendly
/// copy so end users never see endpoint paths, status codes or class names.
String friendlyErrorMessage(dynamic error) {
  if (error == null) {
    return ToastMessages.serverError;
  }

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ToastMessages.timeoutError;
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return ToastMessages.networkError;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 401) {
          return ToastMessages.sessionExpired;
        }
        if (status == 404) {
          return ToastMessages.notFound;
        }
        if (status == 409) {
          return ToastMessages.conflict;
        }
        if (status >= 500) {
          return ToastMessages.serverError;
        }
        return _friendlyFromText(
          error.response?.data is Map
              ? error.response?.data['message']?.toString()
              : error.message,
        );
      case DioExceptionType.unknown:
        return ToastMessages.networkError;
    }
  }

  if (error is UnauthorizedException) {
    return ToastMessages.sessionExpired;
  }
  if (error is BadRequestException) {
    return _friendlyFromText(error.msg);
  }
  if (error is InvalidInputException) {
    return _friendlyFromText(error.msg);
  }
  if (error is FetchDataExceptions) {
    return _friendlyFromText(error.msg);
  }

  if (error is String) {
    return _friendlyFromText(error);
  }

  return _friendlyFromText(error.toString());
}

String _friendlyFromText(String? text) {
  final raw = (text ?? '').trim();
  final lower = raw.toLowerCase();

  if (lower.isEmpty) {
    return ToastMessages.serverError;
  }

  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('temporary failure') ||
      lower.contains('failed to connect') ||
      lower.contains('host lookup') ||
      lower.contains('connection reset')) {
    return ToastMessages.networkError;
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return ToastMessages.timeoutError;
  }
  if (lower.contains('unauthorized') || lower.contains('sign in again')) {
    return ToastMessages.sessionExpired;
  }
  if (lower.contains('not found') ||
      lower.contains('endpoint') ||
      lower.contains('should not exist')) {
    return ToastMessages.notFound;
  }
  if (lower.contains('already') ||
      lower.contains('duplicate') ||
      lower.contains('conflict') ||
      lower.contains('already exists') ||
      lower.contains('already regist')) {
    return ToastMessages.conflict;
  }
  if (lower.contains('null check') || lower.contains('type cast failed')) {
    return ToastMessages.serverError;
  }
  if (lower.contains('check your input')) {
    return ToastMessages.invalidInput;
  }

  // Strip obvious technical noise before showing backend text.
  final cleaned = raw
      .replaceAll(RegExp(r'Endpoint not found:\s*'), '')
      .replaceAll(RegExp(r'\[(InvalidInputException|BadRequestException|FetchDataExceptions|UnauthorizedException)[^\]]*\]'), '')
      .trim();
  if (cleaned.isEmpty) {
    return ToastMessages.serverError;
  }
  return cleaned;
}