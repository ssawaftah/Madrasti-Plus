class AppNotification {
  final String id;
  final String userId;
  final String studentId;
  final String studentName;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'studentId': studentId,
      'studentName': studentName,
      'type': type,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
