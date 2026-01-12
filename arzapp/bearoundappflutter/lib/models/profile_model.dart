import 'package:flutter/foundation.dart';

class PhotoModel {
  final String id;
  final String url;
  final String? blurredUrl;
  final bool isMain;
  final int order;

  PhotoModel({
    required this.id,
    required this.url,
    this.blurredUrl,
    this.isMain = false,
    this.order = 0,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['_id'] ?? json['id'] ?? '',
      url: json['url'] ?? '',
      blurredUrl: json['blurredUrl'],
      isMain: json['isMain'] ?? false,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'url': url,
      'blurredUrl': blurredUrl,
      'isMain': isMain,
      'order': order,
    };
  }
}

class CollegeModel {
  final String? name;
  final int? graduationYear;

  CollegeModel({this.name, this.graduationYear});

  factory CollegeModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CollegeModel();
    return CollegeModel(
      name: json['name'],
      graduationYear: json['graduationYear'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (graduationYear != null) 'graduationYear': graduationYear,
    };
  }
}

class WorkplaceModel {
  final String? company;
  final String? position;

  WorkplaceModel({this.company, this.position});

  factory WorkplaceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return WorkplaceModel();
    return WorkplaceModel(
      company: json['company'],
      position: json['position'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (company != null) 'company': company,
      if (position != null) 'position': position,
    };
  }
}

class LocationModel {
  final String? city;
  final String? state;
  final String? country;

  LocationModel({this.city, this.state, this.country});

  factory LocationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LocationModel();
    return LocationModel(
      city: json['city'],
      state: json['state'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
    };
  }
}

class PromptAnswerModel {
  final String question;
  final String answer;

  PromptAnswerModel({required this.question, required this.answer});

  factory PromptAnswerModel.fromJson(Map<String, dynamic> json) {
    return PromptAnswerModel(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}

class ProfileModel {
  final String id;
  final String? userId;
  final String? username;
  final String name;
  final String? alias;
  final int? age;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<String> interestedIn;
  final String? relationshipIntent;
  final String? bio;
  final List<String> interests;
  final String? whyOnApp;
  final String? lookingFor;
  final List<PhotoModel> photos;
  final LocationModel? location;
  final CollegeModel? college;
  final WorkplaceModel? workplace;
  final List<PromptAnswerModel> promptAnswers;
  final String visibility;
  final bool isComplete;
  final int? matchScore;

  ProfileModel({
    required this.id,
    this.userId,
    this.username,
    required this.name,
    this.alias,
    this.age,
    this.dateOfBirth,
    this.gender,
    this.interestedIn = const [],
    this.relationshipIntent,
    this.bio,
    this.interests = const [],
    this.whyOnApp,
    this.lookingFor,
    this.photos = const [],
    this.location,
    this.college,
    this.workplace,
    this.promptAnswers = const [],
    this.visibility = 'discoverable',
    this.isComplete = false,
    this.matchScore,
  });

  String get mainPhotoUrl {
    if (photos.isEmpty) return '';
    final mainPhoto = photos.firstWhere(
      (p) => p.isMain,
      orElse: () => photos.first,
    );
    return mainPhoto.url;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Parse photos
    List<PhotoModel> photos = [];
    if (json['photos'] != null) {
      try {
        final photosList = json['photos'];
        if (photosList is List) {
          photos = photosList
              .map((p) {
                try {
                  return PhotoModel.fromJson(p);
                } catch (e) {
                  debugPrint('Error parsing photo: $e, photo data: $p');
                  return null;
                }
              })
              .whereType<PhotoModel>()
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing photos array: $e');
      }
    }
    debugPrint('Profile ${json['name']}: Parsed ${photos.length} photos');

    // Parse prompt answers
    List<PromptAnswerModel> promptAnswers = [];
    if (json['promptAnswers'] != null) {
      promptAnswers = (json['promptAnswers'] as List)
          .map((p) => PromptAnswerModel.fromJson(p))
          .toList();
    }

    // Parse interests
    List<String> interests = [];
    if (json['interests'] != null) {
      interests = List<String>.from(json['interests']);
    }

    // Parse interestedIn
    List<String> interestedIn = [];
    if (json['interestedIn'] != null) {
      interestedIn = List<String>.from(json['interestedIn']);
    }

    // Get username from nested user object if available
    String? username = json['username'];
    if (username == null && json['user'] != null) {
      if (json['user'] is Map) {
        username = json['user']['username'];
      }
    }

    // Handle userId - can be a string (ObjectId) or an object with _id
    String? userId;
    if (json['user'] != null) {
      if (json['user'] is String) {
        userId = json['user'] as String;
      } else if (json['user'] is Map) {
        userId = json['user']['_id'] ?? json['user']['id'];
      }
    }
    userId ??= json['userId'];

    return ProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId,
      username: username,
      name: json['name'] ?? '???',
      alias: json['alias'],
      age: json['age'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      interestedIn: interestedIn,
      relationshipIntent: json['relationshipIntent'],
      bio: json['bio'],
      interests: interests,
      whyOnApp: json['whyOnApp'],
      lookingFor: json['lookingFor'],
      photos: photos,
      location: LocationModel.fromJson(json['location']),
      college: CollegeModel.fromJson(json['college']),
      workplace: WorkplaceModel.fromJson(json['workplace']),
      promptAnswers: promptAnswers,
      visibility: json['visibility'] ?? 'discoverable',
      isComplete: json['isComplete'] ?? false,
      matchScore: json['matchScore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'username': username,
      'name': name,
      'alias': alias,
      'age': age,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'interestedIn': interestedIn,
      'relationshipIntent': relationshipIntent,
      'bio': bio,
      'interests': interests,
      'whyOnApp': whyOnApp,
      'lookingFor': lookingFor,
      'photos': photos.map((p) => p.toJson()).toList(),
      'location': location?.toJson(),
      'college': college?.toJson(),
      'workplace': workplace?.toJson(),
      'promptAnswers': promptAnswers.map((p) => p.toJson()).toList(),
      'visibility': visibility,
      'isComplete': isComplete,
      'matchScore': matchScore,
    };
  }
}

