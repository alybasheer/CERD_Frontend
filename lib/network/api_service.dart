import 'package:dio/dio.dart';
import 'package:fyp_source_code/network/exceptions.dart';
import 'package:fyp_source_code/network/get_dio.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart' hide Response;

class DioHelper {
  Dio dio = getDio();
  static const _retryDelay = Duration(seconds: 2);

  void _handleErrorResponse(String url, Response response) {
    if (response.statusCode == 404) {
      throw FetchDataExceptions('Endpoint not found: $url');
    }

    // Validation-list responses (NestJS ValidationPipe) are technical and
    // English-only; collapse them into one friendly, translated message.
    if (response.data is Map && response.data['message'] is List) {
      throw BadRequestException('Please check your input and try again.');
    }

    final errorMsg =
        response.data is Map && response.data['message'] != null
            ? _messageToString(response.data['message'])
            : (response.statusMessage ?? 'Error: ${response.statusCode}');

    print(
      'API ERROR: url=$url status=${response.statusCode} dataType=${response.data.runtimeType} data=${response.data}',
    );

    if (response.statusCode == 400) {
      throw BadRequestException(errorMsg);
    } else if (response.statusCode == 401) {
      _handleUnauthorizedSession();
      throw UnauthorizedException(errorMsg);
    }

    throw FetchDataExceptions(
      errorMsg,
    ); // removed the prefix so it displays clearly
  }

  String _messageToString(dynamic message) {
    if (message is List) {
      return message.map((e) => e?.toString()).where((e) => e != null && e.isNotEmpty).join('. ');
    }
    return message.toString();
  }

  void _handleUnauthorizedSession() {
    StorageHelper().clearSessionData();
    if (Get.currentRoute == RouteNames.login) {
      return;
    }
    Future.microtask(() => Get.offAllNamed(RouteNames.login));
  }

  Future<void> warmUpBackend() async {
    try {
      await _withRetry(() => dio.get('/'), allowRetry: true);
    } catch (_) {
      // Login/request calls still handle their own error state.
    }
  }

  Future<Response> _withRetry(
    Future<Response> Function() request, {
    bool allowRetry = true,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (!allowRetry || !_isRetryableNetworkIssue(e)) {
        rethrow;
      }
      await Future.delayed(_retryDelay);
      return request();
    }
  }

  bool _isRetryableNetworkIssue(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.type == DioExceptionType.unknown && error.response == null);
  }

  FetchDataExceptions _networkException(DioException e) {
    if (_isRetryableNetworkIssue(e)) {
      return FetchDataExceptions(
        'Server is waking up or the network is slow. Please try again.',
      );
    }
    return FetchDataExceptions(e.message ?? 'Network Error');
  }

  //get
  Future<dynamic> get({required String url, bool isauthorize = false}) async {
    try {
      Response response = await _withRetry(
        () => dio.get(url, options: getOptions(isauthorize: isauthorize)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        _handleErrorResponse(url, response);
      }
    } on DioException catch (e) {
      throw _networkException(e);
    }
  }

  //get
  Future<dynamic> put({
    required String url,
    Object? reqBody,
    bool isauthorize = false,
    bool isFormData = false,
  }) async {
    try {
      Response response = await _withRetry(
        () => dio.put(
          url,
          options: getOptions(isFormData: isFormData, isauthorize: isauthorize),
          data: reqBody,
        ),
        allowRetry: !isFormData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        _handleErrorResponse(url, response);
      }
    } on DioException catch (e) {
      throw _networkException(e);
    }
  }

  Future<dynamic> post({
    required String url,
    Object? reqBody,
    bool isauthorize = false,
    bool isFormData = false,
  }) async {
    try {
      Response response = await _withRetry(
        () => dio.post(
          url,
          options: getOptions(isFormData: isFormData, isauthorize: isauthorize),
          data: reqBody,
        ),
        allowRetry: !isFormData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        _handleErrorResponse(url, response);
      }
    } on DioException catch (e) {
      throw _networkException(e);
    }
  }

  Future<dynamic> patch({
    required String url,
    Object? reqBody,
    bool isauthorize = false,
  }) async {
    try {
      Response response = await _withRetry(
        () => dio.patch(
          url,
          options: getOptions(isauthorize: isauthorize),
          data: reqBody,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        _handleErrorResponse(url, response);
      }
    } on DioException catch (e) {
      throw _networkException(e);
    }
  }

  Future<dynamic> delete({
    required String url,
    Object? reqBody,
    bool isauthorize = false,
  }) async {
    try {
      Response response = await _withRetry(
        () => dio.delete(
          url,
          options: getOptions(isauthorize: isauthorize),
          data: reqBody,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        _handleErrorResponse(url, response);
      }
    } on DioException catch (e) {
      throw _networkException(e);
    }
  }
}
