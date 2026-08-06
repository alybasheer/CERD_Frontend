import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Position? _cachedKnownPosition;
DateTime? _cachedKnownPositionAt;

/// Returns a fresh, accurate position. Prefer this when accuracy matters more
/// than speed.
Future<Position> getCurrentLocation({bool useCacheFirst = false}) async {
  if (useCacheFirst) {
    final cached = getCachedKnownPosition();
    if (cached != null) {
      return cached;
    }
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied');
  }

  final current = await Geolocator.getCurrentPosition(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.best,
      forceLocationManager: true,
    ),
  );
  _rememberPosition(current);
  return current;
}

/// Fast position lookup for time-sensitive actions (e.g. SOS).
///
/// Order: cached memory position (≤2 min) → last known platform position
/// (≤2 min) → fresh GPS fix (bounded wait). Never blocks longer than the
/// timeout before falling back to the platform's last-known value.
Future<Position> getQuickPosition() async {
  final cached = _cachedKnownPosition;
  if (cached != null &&
      DateTime.now().difference(_cachedKnownPositionAt!) <
          const Duration(minutes: 2)) {
    return cached;
  }

  try {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      final timestamp = last.timestamp;
      final isRecent =
          DateTime.now().difference(timestamp) < const Duration(minutes: 2);
      if (isRecent) {
        _rememberPosition(last);
        return last;
      }
    }
  } catch (_) {
    // Fall through to a fresh fix.
  }

  final fresh = await getCurrentLocation(
    useCacheFirst: false,
  ).timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      final last = _cachedKnownPosition;
      if (last != null) {
        return last;
      }
      return Future.error('Unable to determine your location.');
    },
  );
  _rememberPosition(fresh);
  return fresh;
}

void _rememberPosition(Position position) {
  _cachedKnownPosition = position;
  _cachedKnownPositionAt = DateTime.now();
}

Position? getCachedKnownPosition() => _cachedKnownPosition;

Future<String> getLocationNameFromCoordinates({
  required double latitude,
  required double longitude,
}) async {
  final normalizedLatitude = latitude.toStringAsFixed(7);
  final normalizedLongitude = longitude.toStringAsFixed(7);

  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) {
      return await _resolveLocationNameWithNetworkFallback(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final place = placemarks.first;
    final parts = <String?>[
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.country,
    ];
    final readableParts =
        parts
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();

    if (readableParts.isNotEmpty) {
      return readableParts.join(', ');
    }

    final fallback = [place.street, place.name]
        .whereType<String>()
        .map((part) => part.trim())
        .firstWhere(
          (part) => part.isNotEmpty,
          orElse: () => 'Location unavailable',
        );
    return fallback;
  } catch (_) {
    final fallback = await _resolveLocationNameWithNetworkFallback(
      latitude: latitude,
      longitude: longitude,
    );
    if (fallback != 'Location unavailable') {
      return fallback;
    }
    return 'Near $normalizedLatitude, $normalizedLongitude';
  }
}

Future<String> resolveLocationLabel(String value) async {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      isGenericLocationLabel(trimmed) ||
      trimmed == 'Location not set') {
    final position = await getCurrentLocation();
    return getLocationNameFromCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  final coordinates = parseCoordinateText(trimmed);
  if (coordinates != null) {
    return getLocationNameFromCoordinates(
      latitude: coordinates.$1,
      longitude: coordinates.$2,
    );
  }

  return trimmed;
}

bool isGenericLocationLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return normalized == 'current location' ||
      normalized == 'location unavailable' ||
      normalized == 'location auto-detected' ||
      normalized == 'resolving nearby area...' ||
      normalized == 'finding nearby area...' ||
      normalized.contains('lat ') ||
      normalized.contains('lng') ||
      parseCoordinateText(normalized) != null;
}

(double, double)? parseCoordinateText(String value) {
  final normalized = value.trim();
  final latLngPattern = RegExp(
    r'lat(?:itude)?\s*[: ]\s*(-?\d+(?:\.\d+)?)[,\s]+lng|lon|longitude',
    caseSensitive: false,
  );
  final latMatch = RegExp(
    r'lat(?:itude)?\s*[: ]\s*(-?\d+(?:\.\d+)?)',
    caseSensitive: false,
  ).firstMatch(normalized);
  final lngMatch = RegExp(
    r'(?:lng|lon|longitude)\s*[: ]\s*(-?\d+(?:\.\d+)?)',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (latMatch != null && lngMatch != null) {
    final lat = double.tryParse(latMatch.group(1)!);
    final lng = double.tryParse(lngMatch.group(1)!);
    if (lat != null && lng != null) {
      return (lat, lng);
    }
  }

  final plainParts = normalized.split(RegExp(r'\s*,\s*'));
  if (plainParts.length == 2) {
    final first = double.tryParse(plainParts[0]);
    final second = double.tryParse(plainParts[1]);
    if (first != null && second != null) {
      return (first, second);
    }
  }

  // Keep this variable referenced so accidental simplification does not hide
  // malformed labels like "Lat 1, Lng 2".
  latLngPattern.hasMatch(normalized);
  return null;
}

Future<String> _resolveLocationNameWithNetworkFallback({
  required double latitude,
  required double longitude,
}) async {
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'zoom': '18',
      'addressdetails': '1',
    });
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'WeHelpApp/1.0 location display',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'Location unavailable';
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      return 'Location unavailable';
    }

    final address =
        json['address'] is Map
            ? Map<String, dynamic>.from(json['address'] as Map)
            : <String, dynamic>{};
    final parts = <String?>[
      address['road']?.toString(),
      address['neighbourhood']?.toString(),
      address['suburb']?.toString(),
      address['city']?.toString() ?? address['town']?.toString(),
      address['state']?.toString(),
      address['country']?.toString(),
    ];
    final readableParts =
        parts
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .take(4)
            .toList();

    if (readableParts.isNotEmpty) {
      return readableParts.join(', ');
    }

    final displayName = json['display_name']?.toString().trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(',').take(4).map((e) => e.trim()).join(', ');
    }
  } catch (_) {
    return 'Location unavailable';
  }

  return 'Location unavailable';
}
