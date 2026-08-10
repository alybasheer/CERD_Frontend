import 'package:fyp_source_code/services/location_services.dart';

class HelpRequestLocation {
  String? type;
  List<double>? coordinates;

  HelpRequestLocation({this.type, this.coordinates});

  HelpRequestLocation.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    if (json['coordinates'] is List) {
      coordinates =
          (json['coordinates'] as List)
              .whereType<num>()
              .map((e) => e.toDouble())
              .toList();
    } else {
      final lat = _readDouble(json['latitude'] ?? json['lat']);
      final lng = _readDouble(json['longitude'] ?? json['lng']);
      if (lat != null && lng != null) {
        type = 'Point';
        coordinates = [lng, lat];
      }
    }
  }

  HelpRequestLocation.fromLatLng({required double lat, required double lng}) {
    type = 'Point';
    coordinates = [lng, lat];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['type'] = type;
    data['coordinates'] = coordinates;
    return data;
  }

  double? get longitude {
    if (coordinates == null || coordinates!.length < 2) {
      return null;
    }
    return coordinates![0];
  }

  double? get latitude {
    if (coordinates == null || coordinates!.length < 2) {
      return null;
    }
    return coordinates![1];
  }
}

class HelpRequest {
  String? sId;
  String? userId;
  String? userName;
  String? title;
  String? category;
  String? subCategory;
  String? description;
  String? image;
  List<String> mediaUrls = <String>[];
  String? requesterImage;
  String? locationName;
  HelpRequestLocation? location;
  String? status;
  String? acceptedBy;
  String? acceptedByName;
  bool isSos = false;
  int? notifiedCount;
  double? rating;
  String? outcome;
  String? expiresAt;
  String? createdAt;
  String? updatedAt;

  HelpRequest({
    this.sId,
    this.userId,
    this.userName,
    this.title,
    this.category,
    this.subCategory,
    this.description,
    this.image,
    List<String>? mediaUrls,
    this.requesterImage,
    this.locationName,
    this.location,
    this.status,
    this.acceptedBy,
    this.acceptedByName,
    this.isSos = false,
    this.notifiedCount,
    this.rating,
    this.outcome,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  }) : mediaUrls = mediaUrls ?? <String>[];

  HelpRequest.fromJson(Map<String, dynamic> json) {
    final userRef = json['userId'] ?? json['user'] ?? json['requestee'];
    final acceptedRef = json['acceptedBy'] ?? json['volunteer'];

    sId = _readId(json);
    userId = _readRefId(userRef);
    userName =
        _readRefName(userRef) ??
        json['userName']?.toString() ??
        json['requesteeName']?.toString();
    title = json['title']?.toString();
    category = json['category']?.toString();
    subCategory = json['subCategory']?.toString();
    description = json['description']?.toString();
    final parsedMediaUrls = _readStringList(
      json['mediaUrls'] ?? json['media'] ?? json['images'],
    );
    image = _readFirstString([
      json['image'],
      json['imageUrl'],
      json['mediaUrl'],
      _readFirstFromList(parsedMediaUrls),
    ]);
    mediaUrls = _uniqueStrings([...parsedMediaUrls, if (image != null) image!]);
    requesterImage = _readFirstString([
      json['requesterImage'],
      json['requesterImageUrl'],
      json['profileImage'],
      json['profileImageUrl'],
      _readRefImage(userRef),
    ]);
    locationName =
        json['locationName']?.toString() ?? json['address']?.toString();
    if (json['location'] is Map) {
      location = HelpRequestLocation.fromJson(
        Map<String, dynamic>.from(json['location']),
      );
    } else {
      final lat = _readDouble(json['latitude'] ?? json['lat']);
      final lng = _readDouble(json['longitude'] ?? json['lng']);
      if (lat != null && lng != null) {
        location = HelpRequestLocation.fromLatLng(lat: lat, lng: lng);
      }
    }
    status = json['status']?.toString();
    acceptedBy = _readRefId(acceptedRef);
    acceptedByName =
        _readRefName(acceptedRef) ?? json['acceptedByName']?.toString();
    isSos =
        _readBool(json['isSos']) ||
        _readBool(json['sos']) ||
        (category?.toLowerCase() == 'sos');
    notifiedCount = _readInt(json['notifiedCount']);
    rating = _readDouble(json['rating'] ?? json['volunteerRating']);
    outcome = json['outcome']?.toString();
    expiresAt = json['expiresAt']?.toString();
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
  }

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!;
    }
    if (isSos) {
      return 'SOS Request';
    }
    if (category != null && subCategory != null) {
      return '$category - $subCategory';
    }
    return category ?? 'Emergency Request';
  }

  String get displayLocation {
    if (locationName != null &&
        locationName!.trim().isNotEmpty &&
        !isGenericLocationLabel(locationName!)) {
      return locationName!;
    }
    return 'Resolving nearby area...';
  }

  String? get displayImage {
    return _readFirstString([
      _readFirstFromList(displayMediaUrls),
      requesterImage,
    ]);
  }

  List<String> get displayMediaUrls {
    if (mediaUrls.isNotEmpty) {
      return mediaUrls;
    }
    return _uniqueStrings([if (image != null) image!]);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['userName'] = userName;
    data['title'] = title;
    data['category'] = category;
    data['subCategory'] = subCategory;
    data['description'] = description;
    data['image'] = image;
    data['mediaUrls'] = mediaUrls;
    data['requesterImage'] = requesterImage;
    data['locationName'] = locationName;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['status'] = status;
    data['acceptedBy'] = acceptedBy;
    data['acceptedByName'] = acceptedByName;
    data['isSos'] = isSos;
    data['rating'] = rating;
    data['outcome'] = outcome;
    data['expiresAt'] = expiresAt;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}

class NearbyVolunteer {
  final String id;
  final String name;
  final String email;
  final String expertise;
  final double ratingAverage;
  final int ratingCount;
  final bool isOnline;
  final double? distanceKm;
  final String? locationName;

  NearbyVolunteer({
    required this.id,
    required this.name,
    required this.email,
    required this.expertise,
    required this.ratingAverage,
    required this.ratingCount,
    required this.isOnline,
    this.distanceKm,
    this.locationName,
  });

  factory NearbyVolunteer.fromJson(Map<String, dynamic> json) {
    final user =
        json['user'] is Map ? Map<String, dynamic>.from(json['user']) : json;
    final expertiseValue =
        user['expertise'] ?? user['skills'] ?? user['category'] ?? 'General';
    final expertise =
        expertiseValue is List
            ? expertiseValue.join(', ')
            : expertiseValue.toString();

    return NearbyVolunteer(
      id: _readRefId(user) ?? '',
      name:
          user['username']?.toString() ??
          user['name']?.toString() ??
          'Volunteer',
      email: user['email']?.toString() ?? '',
      expertise: expertise.isEmpty ? 'General' : expertise,
      ratingAverage:
          _readDouble(
            user['ratingAverage'] ??
                user['averageRating'] ??
                user['rating'] ??
                _readNestedValue(user['stats'], 'ratingAverage') ??
                _readNestedValue(user['stats'], 'averageRating'),
          ) ??
          0,
      ratingCount: _readInt(
            user['ratingCount'] ??
                user['ratingsCount'] ??
                user['totalRatings'] ??
                _readNestedValue(user['stats'], 'ratingCount') ??
                _readNestedValue(user['stats'], 'ratingsCount'),
          ) ??
          0,
      isOnline: _readBool(
        user['isOnline'] ?? user['online'] ?? json['isOnline'],
      ),
      distanceKm: _readDouble(json['distanceKm'] ?? json['distance']),
      locationName:
          user['locationName']?.toString() ?? json['locationName']?.toString(),
    );
  }
}

String? _readId(Map<String, dynamic> json) {
  return json['_id']?.toString() ?? json['id']?.toString();
}

String? _readRefId(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Map) {
    return value['_id']?.toString() ?? value['id']?.toString();
  }
  return value.toString();
}

String? _readRefName(dynamic value) {
  if (value is Map) {
    return value['username']?.toString() ?? value['name']?.toString();
  }
  return null;
}

String? _readRefImage(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return _readFirstString([
    value['image'],
    value['imageUrl'],
    value['profileImage'],
    value['profileImageUrl'],
    value['avatar'],
    value['avatarUrl'],
    value['photoUrl'],
    value['photoURL'],
  ]);
}

String? _readFirstString(List<dynamic> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }

  return null;
}

String? _readFirstFromList(dynamic value) {
  if (value is List) {
    for (final item in value) {
      final text = item?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
  }

  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }

  return _uniqueStrings(
    value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty && item.toLowerCase() != 'null'),
  );
}

List<String> _uniqueStrings(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};

  for (final value in values) {
    final text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      continue;
    }
    if (seen.add(text)) {
      result.add(text);
    }
  }

  return result;
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

bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return false;
}
