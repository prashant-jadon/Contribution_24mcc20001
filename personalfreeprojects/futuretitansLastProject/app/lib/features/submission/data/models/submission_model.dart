class SubmissionModel {
  final String? id;
  final String title;
  final String description;
  final String status;
  final Map<String, dynamic> formData;
  final List<String> attachments; // URLs or paths
  
  SubmissionModel({
    this.id,
    required this.title,
    required this.description,
    this.status = 'draft',
    this.formData = const {},
    this.attachments = const [],
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'draft',
      formData: json['formData'] ?? {},
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'status': status,
      'formData': formData,
      'attachments': attachments,
    };
  }
}
