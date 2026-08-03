import 'package:dio/dio.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/services/api_names.dart';

class RequestMediaUpload {
  final String filename;
  final List<int> bytes;
  final String? mimeType;

  const RequestMediaUpload({
    required this.filename,
    required this.bytes,
    this.mimeType,
  });
}

class HelpRequestRepo {
  final DioHelper _dioHelper = DioHelper();

  Future<HelpRequest> createRequest(Object? reqBody) async {
    final response = await _dioHelper.post(
      url: ApiNames.helpRequests,
      reqBody: reqBody,
      isauthorize: true,
    );

    return _parseRequest(response);
  }

  Future<List<String>> uploadRequestMedia(
    List<RequestMediaUpload> files,
  ) async {
    if (files.isEmpty) {
      return <String>[];
    }

    final formData = FormData.fromMap({
      'files':
          files.map((file) {
            return MultipartFile.fromBytes(
              file.bytes,
              filename: file.filename,
              contentType:
                  file.mimeType == null
                      ? null
                      : DioMediaType.parse(file.mimeType!),
            );
          }).toList(),
    });

    final response = await _dioHelper.post(
      url: ApiNames.helpRequestMedia,
      reqBody: formData,
      isauthorize: true,
      isFormData: true,
    );

    return _parseMediaUrls(response);
  }

  Future<SosResult> createSos(Object? reqBody) async {
    final response = await _dioHelper.post(
      url: ApiNames.helpRequestsSos,
      reqBody: reqBody,
      isauthorize: true,
    );

    final request = _parseRequest(response);
    final dataMap = _extractDataMap(response);
    return SosResult(
      request: request,
      alreadyActive: dataMap['alreadyActive'] == true,
      notified: int.tryParse(dataMap['notified']?.toString() ?? '') ?? 0,
    );
  }

  Future<void> cancelSos() async {
    await _dioHelper.post(
      url: ApiNames.helpRequestsSosCancel,
      reqBody: const {},
      isauthorize: true,
    );
  }

  Map<String, dynamic> _extractDataMap(dynamic response) {
    if (response is! Map) {
      return {};
    }
    final responseMap = Map<String, dynamic>.from(response);
    final data = responseMap['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  List<String> _parseMediaUrls(dynamic response) {
    if (response is Map) {
      final responseMap = Map<String, dynamic>.from(response);
      final data = responseMap['data'];

      for (final value in [
        responseMap['mediaUrls'],
        responseMap['urls'],
        data is Map ? data['mediaUrls'] : null,
        data is Map ? data['urls'] : null,
        data,
      ]) {
        final urls = _readStringList(value);
        if (urls.isNotEmpty) {
          return urls;
        }
      }
    }

    if (response is List) {
      return _readStringList(response);
    }

    return <String>[];
  }

  Future<List<HelpRequest>> getOpenRequests({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
  }) async {
    String url = ApiNames.helpRequests;
    if (latitude != null && longitude != null) {
      url = '$url?lat=$latitude&lng=$longitude&radius=$radiusKm';
    }

    final response = await _dioHelper.get(url: url, isauthorize: true);
    return _parseRequests(response);
  }

  Future<List<HelpRequest>> getMyActiveRequests() async {
    final response = await _dioHelper.get(
      url: ApiNames.activeHelpRequests,
      isauthorize: true,
    );

    return _parseRequests(response);
  }

  Future<List<NearbyVolunteer>> getNearbyVolunteers({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    bool onlineOnly = true,
  }) async {
    final response = await _dioHelper.get(
      url: ApiNames.nearbyVolunteers(
        lat: latitude,
        lng: longitude,
        radius: radiusKm,
        onlineOnly: onlineOnly,
      ),
      isauthorize: true,
    );

    return _extractList(response, listKeys: const ['volunteers', 'users'])
        .map((e) => NearbyVolunteer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<HelpRequest> acceptRequest(String id) async {
    final response = await _dioHelper.patch(
      url: ApiNames.acceptHelpRequest(id),
      isauthorize: true,
    );

    return _parseRequest(response);
  }

  Future<HelpRequest> releaseRequest(String id) async {
    final response = await _dioHelper.patch(
      url: ApiNames.releaseHelpRequest(id),
      isauthorize: true,
    );

    return _parseRequest(response);
  }

  Future<HelpRequest> resolveRequest(String id) async {
    final response = await _dioHelper.patch(
      url: ApiNames.resolveHelpRequest(id),
      isauthorize: true,
    );

    return _parseRequest(response);
  }

  Future<dynamic> rateRequest(
    String id, {
    required int score,
    String? comment,
  }) async {
    return _dioHelper.post(
      url: ApiNames.rateHelpRequest(id),
      reqBody: {'score': score, if (comment != null) 'comment': comment},
      isauthorize: true,
    );
  }

  HelpRequest _parseRequest(dynamic response) {
    if (response is Map) {
      final responseMap = Map<String, dynamic>.from(response);
      final data = responseMap['data'];

      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        if (dataMap['request'] is Map) {
          return HelpRequest.fromJson(
            Map<String, dynamic>.from(dataMap['request']),
          );
        }
        if (dataMap['helpRequest'] is Map) {
          return HelpRequest.fromJson(
            Map<String, dynamic>.from(dataMap['helpRequest']),
          );
        }
        return HelpRequest.fromJson(dataMap);
      }

      if (responseMap['request'] is Map) {
        return HelpRequest.fromJson(
          Map<String, dynamic>.from(responseMap['request']),
        );
      }

      return HelpRequest.fromJson(responseMap);
    }

    throw Exception('Unexpected response format for help request');
  }

  List<HelpRequest> _parseRequests(dynamic response) {
    return _extractList(
      response,
      listKeys: const ['requests', 'helpRequests', 'data'],
    ).map((e) => HelpRequest.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<dynamic> _extractList(
    dynamic response, {
    required List<String> listKeys,
  }) {
    if (response is List) {
      return response;
    }

    if (response is Map) {
      final responseMap = Map<String, dynamic>.from(response);
      final data = responseMap['data'];

      if (data is List) {
        return data;
      }

      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        for (final key in listKeys) {
          if (dataMap[key] is List) {
            return dataMap[key] as List;
          }
        }
      }

      for (final key in listKeys) {
        if (responseMap[key] is List) {
          return responseMap[key] as List;
        }
      }
    }

    return <dynamic>[];
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty && item.toLowerCase() != 'null')
        .toList();
  }
}

class SosResult {
  final HelpRequest request;
  final bool alreadyActive;
  final int notified;

  const SosResult({
    required this.request,
    this.alreadyActive = false,
    this.notified = 0,
  });
}
