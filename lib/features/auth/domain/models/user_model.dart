// lib/features/auth/domain/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String career;
  final int semester;
  final List<String> roles;
  final String? avatarUrl;
  final ProfileModel? profile;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.career,
    required this.semester,
    required this.roles,
    this.avatarUrl,
    this.profile,
  });

  bool get isTutor => roles.contains('tutor');
  bool get isAdmin => roles.contains('admin');
  String get firstName => fullName.split(' ').first;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    fullName: json['full_name'] ?? '',
    career: json['career'] ?? '',
    semester: json['semester'] ?? 1,
    roles: List<String>.from(json['roles'] ?? ['tutee']),
    avatarUrl: json['avatar_url'],
    profile: json['profile'] != null ? ProfileModel.fromJson(json['profile']) : null,
  );
}

class ProfileModel {
  final String bio;
  final double rating;
  final int totalSessions;
  final double attendanceRate;
  final List<String> subjects;

  ProfileModel({
    required this.bio,
    required this.rating,
    required this.totalSessions,
    required this.attendanceRate,
    required this.subjects,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    bio: json['bio'] ?? '',
    rating: (json['rating'] ?? 0).toDouble(),
    totalSessions: json['total_sessions'] ?? 0,
    attendanceRate: (json['attendance_rate'] ?? 100).toDouble(),
    subjects: List<String>.from(json['subjects'] ?? []),
  );
}
