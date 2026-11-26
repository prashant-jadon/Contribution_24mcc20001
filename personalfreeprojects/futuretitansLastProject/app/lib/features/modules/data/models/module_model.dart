class ModuleModel {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int estimatedTime; // in minutes
  final String? coverImage;
  final String? mentorProfilePicture;
  final bool aiInteractionEnabled;
  final List<ChapterModel> chapters;
  final int progress; // 0-100 percentage
  final bool isCompleted;
  final bool isPublished;

  ModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedTime,
    this.coverImage,
    this.mentorProfilePicture,
    this.aiInteractionEnabled = true,
    required this.chapters,
    this.progress = 0,
    this.isCompleted = false,
    this.isPublished = false,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    // userProgress is attached inline by backend for student requests
    final userProgress = json['userProgress'] as Map<String, dynamic>?;
    final completionPct = (userProgress?['completionPercentage'] ?? 0);

    // Parse chapters — they may be full objects or just IDs
    List<ChapterModel> chapters = [];
    if (json['chapters'] is List) {
      chapters = (json['chapters'] as List).whereType<Map<String, dynamic>>().map((c) => ChapterModel.fromJson(c)).toList();
    }

    return ModuleModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      estimatedTime: json['estimatedCompletionTime'] ?? json['estimatedTime'] ?? 0,
      coverImage: json['coverImage'],
      mentorProfilePicture: json['mentorProfilePicture'],
      aiInteractionEnabled: json['aiInteractionEnabled'] ?? true,
      chapters: chapters,
      progress: completionPct is int ? completionPct : (completionPct as num).toInt(),
      isCompleted: completionPct >= 100,
      isPublished: json['isPublished'] ?? false,
    );
  }
}

class ChapterModel {
  final String id;
  final String title;
  final String description;
  final String content; // text content
  final String type; // text, video, audio, pdf
  final String? videoUrl;
  final String? audioUrl;
  final String? pdfUrl;
  final int order;
  final int estimatedTime;
  final bool aiInteractionEnabled;
  final String? subtitles; // AI context string
  final String? aiPrompt;
  final String? surgeDimensionFocus;

  ChapterModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.content,
    required this.type,
    this.videoUrl,
    this.audioUrl,
    this.pdfUrl,
    required this.order,
    this.estimatedTime = 0,
    this.aiInteractionEnabled = true,
    this.subtitles,
    this.aiPrompt,
    this.surgeDimensionFocus,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    // Backend Chapter has content as an object: { text, type, videoUrl, audioUrl, pdfUrl }
    final contentObj = json['content'];
    String textContent = '';
    String contentType = 'text';
    String? videoUrl;
    String? audioUrl;
    String? pdfUrl;

    if (contentObj is Map<String, dynamic>) {
      textContent = contentObj['text'] ?? '';
      contentType = contentObj['type'] ?? 'text';
      videoUrl = contentObj['videoUrl'];
      audioUrl = contentObj['audioUrl'];
      pdfUrl = contentObj['pdfUrl'];
    } else if (contentObj is String) {
      textContent = contentObj;
    }

    return ChapterModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: textContent,
      type: contentType,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      pdfUrl: pdfUrl,
      order: json['order'] ?? 0,
      estimatedTime: json['estimatedTime'] ?? 0,
      aiInteractionEnabled: json['aiInteractionEnabled'] ?? true,
      subtitles: json['subtitles']?.toString(),
      aiPrompt: json['aiPrompt']?.toString(),
      surgeDimensionFocus: json['surgeDimensionFocus']?.toString(),
    );
  }
}

