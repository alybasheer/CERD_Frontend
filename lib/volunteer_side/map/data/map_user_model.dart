import 'package:latlong2/latlong.dart';

class MapUserModel {
  final String id;
  final String name;
  final String role;
  final LatLng location;
  final double ratingAverage;
  final int ratingCount;
  final int completedCount;

  MapUserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.ratingAverage,
    required this.ratingCount,
    required this.completedCount,
  });

  bool get isVolunteer => role.toLowerCase() == 'volunteer';

  factory MapUserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : json;
    final location =
        user['location'] is Map
            ? Map<String, dynamic>.from(user['location'])
            : <String, dynamic>{};
    final coordinates =
        location['coordinates'] is List
            ? location['coordinates'] as List
            : const [];
    final lng = coordinates.isNotEmpty ? _readDouble(coordinates[0]) : null;
    final lat = coordinates.length > 1 ? _readDouble(coordinates[1]) : null;

    return MapUserModel(
      id: user['_id']?.toString() ?? user['id']?.toString() ?? '',
      name: user['username']?.toString() ?? user['name']?.toString() ?? 'User',
      role: user['role']?.toString() ?? 'requestee',
      location: LatLng(
        lat ?? _readDouble(user['latitude'] ?? user['lat']) ?? 0,
        lng ?? _readDouble(user['longitude'] ?? user['lng']) ?? 0,
      ),
      ratingAverage:
          _readDouble(
            user['ratingAverage'] ??
                user['averageRating'] ??
                user['rating'] ??
                _readNestedValue(user['stats'], 'ratingAverage') ??
                _readNestedValue(user['stats'], 'averageRating'),
          ) ??
          0,
      ratingCount:
          _readInt(
            user['ratingCount'] ??
                user['ratingsCount'] ??
                user['totalRatings'] ??
                _readNestedValue(user['stats'], 'ratingCount') ??
                _readNestedValue(user['stats'], 'ratingsCount'),
          ) ??
          0,
      completedCount:
          _readInt(
            user['completedCount'] ??
                user['completedRequests'] ??
                user['resolvedRequests'] ??
                user['totalCompleted'] ??
                user['helpRequestsCompleted'] ??
                _readNestedValue(user['stats'], 'completedCount') ??
                _readNestedValue(user['stats'], 'completedRequests'),
          ) ??
          0,
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

dynamic _readNestedValue(dynamic value, String key) {
  if (value is Map) {
    return value[key];
  }
  return null;
}
