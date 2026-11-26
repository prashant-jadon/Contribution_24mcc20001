class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? school;
  final String? schoolSlug;
  final String? city;
  final String? country;
  final String? profilePicture;
  final num ssiScore;
  final Map<String, dynamic>? ssiBreakdown;
  final bool isPaid;
  final String? bio;
  final List<ModuleProgress> modulesProgress;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.school,
    this.schoolSlug,
    this.city,
    this.country,
    this.profilePicture,
    this.ssiScore = 0,
    this.ssiBreakdown,
    this.isPaid = false,
    this.bio,
    this.modulesProgress = const [],
  });

  // Alias for compatibility
  bool get hasPaid => isPaid;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'student',
      phone: json['phone'],
      school: json['school'],
      schoolSlug: json['schoolSlug'],
      city: json['city'],
      country: json['country'],
      profilePicture: json['profilePicture'],
      ssiScore: json['ssiScore'] ?? 0,
      ssiBreakdown: json['ssiBreakdown'] as Map<String, dynamic>?,
      isPaid: json['isPaid'] ?? false,
      bio: json['bio'],
      modulesProgress: (json['modulesProgress'] as List<dynamic>?)
              ?.map((e) => ModuleProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'school': school,
      'schoolSlug': schoolSlug,
      'city': city,
      'country': country,
      'profilePicture': profilePicture,
      'ssiScore': ssiScore,
      'ssiBreakdown': ssiBreakdown,
      'isPaid': isPaid,
      'bio': bio,
      'modulesProgress': modulesProgress.map((e) => e.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? school,
    String? city,
    String? country,
    String? profilePicture,
    num? ssiScore,
    Map<String, dynamic>? ssiBreakdown,
    bool? isPaid,
    String? bio,
    List<ModuleProgress>? modulesProgress,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      schoolSlug: schoolSlug,
      city: city ?? this.city,
      country: country ?? this.country,
      profilePicture: profilePicture ?? this.profilePicture,
      ssiScore: ssiScore ?? this.ssiScore,
      ssiBreakdown: ssiBreakdown ?? this.ssiBreakdown,
      isPaid: isPaid ?? this.isPaid,
      bio: bio ?? this.bio,
      modulesProgress: modulesProgress ?? this.modulesProgress,
    );
  }
}

class ModuleProgress {
  final String moduleId;
  final String moduleTitle;
  final List<String> completedChapters;
  final int completionPercentage;
  final int timeSpent; // in seconds

  ModuleProgress({
    required this.moduleId,
    this.moduleTitle = '',
    required this.completedChapters,
    required this.completionPercentage,
    required this.timeSpent,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    String mId = '';
    String mTitle = '';
    if (json['moduleId'] is Map<String, dynamic>) {
      mId = json['moduleId']['_id'] ?? '';
      mTitle = json['moduleId']['title'] ?? '';
    } else {
      mId = json['moduleId']?.toString() ?? '';
    }

    return ModuleProgress(
      moduleId: mId,
      moduleTitle: mTitle,
      completedChapters: (json['completedChapters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completionPercentage: json['completionPercentage'] ?? 0,
      timeSpent: json['timeSpent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,   // Serialization ignores the nested object structure for simplicity
      'moduleTitle': moduleTitle,
      'completedChapters': completedChapters,
      'completionPercentage': completionPercentage,
      'timeSpent': timeSpent,
    };
  }
}
