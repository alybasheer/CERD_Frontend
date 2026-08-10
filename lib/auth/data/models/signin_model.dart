class SignupModel {
  User? user;
  String? accessToken;

  SignupModel({this.user, this.accessToken});

  SignupModel.fromJson(Map<String, dynamic> json) {
    // Normalize response: API may return token/user at root or under 'data'
    Map<String, dynamic> root = Map<String, dynamic>.from(json);
    if (json['data'] != null && json['data'] is Map) {
      root = Map<String, dynamic>.from(json['data']);
    }

    // Handle both nested and flat user structures
    if (root['user'] != null && root['user'] is Map) {
      user = User.fromJson(Map<String, dynamic>.from(root['user']));
    } else if (json['user'] != null && json['user'] is Map) {
      user = User.fromJson(Map<String, dynamic>.from(json['user']));
    } else {
      // Fallback: parse from flat structure
      user = User(
        username: root['username'] ?? json['username'],
        email: root['email'] ?? json['email'],
        password: root['password'] ?? json['password'],
        role: root['role'] ?? json['role'],
      );
    }

    // Support multiple possible token keys
    accessToken =
        root['access_token'] ??
        root['token'] ??
        root['accessToken'] ??
        json['access_token'] ??
        json['token'] ??
        json['accessToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // Send flat structure: username, email, password at root level (backend expects this)
    if (user != null) {
      if (user!.username != null) {
        data['username'] = user!.username;
      }
      data['email'] = user!.email;
      data['password'] = user!.password;
      if (user!.role != null) {
        data['role'] = user!.role;
      }
    }
    if (accessToken != null) {
      data['access_token'] = accessToken;
    }
    return data;
  }

  // Copy with for immutability
  SignupModel copyWith({User? user, String? accessToken}) {
    return SignupModel(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  @override
  String toString() => 'SignupModel(user: $user, accessToken: $accessToken)';
}

class User {
  String? id;
  String? username;
  String? email;
  String? password;
  String? role;
  String? fullName;
  String? location;
  String? profileImage;
  String? verificationStatus; // NEW: Add verification status from backend

  User({
    this.username,
    this.email,
    this.password,
    this.role,
    this.fullName,
    this.location,
    this.profileImage,
    this.id,
    this.verificationStatus, // NEW: Include in constructor
  });

  User.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    fullName = json['name'] ?? json['fullName'] ?? json['full_name'];
    email = json['email'];
    password = json['password'];
    role = json['role'];
    id = json['_id'] ?? json['id'];
    final rawLocation =
        json['location'] ?? json['city'] ?? json['locationName'] ?? json['area'];
    location = _normalizeLocation(rawLocation);
    profileImage =
        json['profileImage'] ??
        json['profile_image'] ??
        json['avatar'] ??
        json['image'];

    // Parse verificationStatus with multiple field name support
    verificationStatus =
        json['verificationStatus'] ??
        json['verification_status'] ??
        json['status'] ??
        json['verifyStatus'];

    print(
      '🔍 User.fromJson - Parsed verificationStatus: $verificationStatus from: ${json.keys}',
    );
  }

  String? _normalizeLocation(dynamic rawLocation) {
    if (rawLocation == null) {
      return null;
    }
    if (rawLocation is String) {
      return rawLocation;
    }
    if (rawLocation is Map) {
      final map = Map<String, dynamic>.from(rawLocation);
      final name = map['name'] ?? map['address'] ?? map['label'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
      final coords = map['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = coords[0];
        final lat = coords[1];
        return '${lat.toString()}, ${lng.toString()}';
      }
    }
    return rawLocation.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['username'] = username;
    if (fullName != null) {
      data['name'] = fullName;
    }
    data['email'] = email;
    data['password'] = password;
    data['role'] = role;
    if (location != null) {
      data['location'] = location;
    }
    if (profileImage != null) {
      data['profileImage'] = profileImage;
    }
    if (id != null) {
      data['id'] = id;
    }
    if (verificationStatus != null) {
      data['verificationStatus'] = verificationStatus;
    }
    return data;
  }

  // Copy with for immutability
  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? password,
    String? role,
    String? location,
    String? profileImage,
    String? verificationStatus,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, fullName: $fullName, email: $email, role: $role, location: $location, profileImage: $profileImage, verificationStatus: $verificationStatus)';
}
