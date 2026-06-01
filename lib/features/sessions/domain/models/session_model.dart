// lib/features/sessions/domain/models/session_model.dart
import '../../../auth/domain/models/user_model.dart';

class SessionModel {
  final String id;
  final String tutorId;
  final String title;
  final String subject;
  final String description;
  final String modality;
  final String? location;
  final String? meetLink;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int maxSpots;
  final int availableSpots;
  final double cost;
  final String difficulty;
  final String sessionType;
  final List<String> tags;
  final String status;
  final UserModel? tutor;
  final ProfileModel? tutorProfile;
  final bool isEnrolled;
  final bool isOwner;

  SessionModel({
    required this.id,
    required this.tutorId,
    required this.title,
    required this.subject,
    required this.description,
    required this.modality,
    this.location,
    this.meetLink,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.maxSpots,
    required this.availableSpots,
    required this.cost,
    required this.difficulty,
    required this.sessionType,
    required this.tags,
    required this.status,
    this.tutor,
    this.tutorProfile,
    this.isEnrolled = false,
    this.isOwner = false,
  });

  bool get isFree => cost == 0;
  bool get isAvailable => status == 'available' && availableSpots > 0;

  String get modalityLabel => modality == 'virtual' ? 'Virtual' : 'Presencial';
  String get difficultyLabel => {
    'basic': 'Basico',
    'intermediate': 'Intermedio',
    'advanced': 'Avanzado',
    'any': 'Cualquier nivel',
  }[difficulty] ?? difficulty;

  String get statusLabel => {
    'available': 'Disponible',
    'full': 'Lleno',
    'in_progress': 'En curso',
    'completed': 'Completada',
    'cancelled': 'Cancelada',
  }[status] ?? status;

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    id: json['id'] ?? '',
    tutorId: json['tutor_id'] ?? '',
    title: json['title'] ?? '',
    subject: json['subject'] ?? '',
    description: json['description'] ?? '',
    modality: json['modality'] ?? 'virtual',
    location: json['location'],
    meetLink: json['meet_link'],
    scheduledAt: DateTime.tryParse(json['scheduled_at'] ?? '') ?? DateTime.now(),
    durationMinutes: json['duration_minutes'] ?? 60,
    maxSpots: json['max_spots'] ?? 1,
    availableSpots: json['available_spots'] ?? 0,
    cost: (json['cost'] ?? 0).toDouble(),
    difficulty: json['difficulty'] ?? 'intermediate',
    sessionType: json['session_type'] ?? 'scheduled',
    tags: List<String>.from(json['tags'] ?? []),
    status: json['status'] ?? 'available',
    tutor: json['tutor'] != null ? UserModel.fromJson(json['tutor']) : null,
    tutorProfile: json['tutor_profile'] != null
        ? ProfileModel.fromJson(json['tutor_profile'])
        : json['tutor']?['profile'] != null
            ? ProfileModel.fromJson(json['tutor']['profile'])
            : null,
    isEnrolled: json['is_enrolled'] ?? false,
    isOwner: json['is_owner'] ?? false,
  );
}

class EnrollmentModel {
  final String id;
  final String sessionId;
  final String userId;
  final String status;
  final DateTime enrolledAt;

  EnrollmentModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.status,
    required this.enrolledAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) => EnrollmentModel(
    id: json['id'] ?? '',
    sessionId: json['session_id'] ?? '',
    userId: json['user_id'] ?? '',
    status: json['status'] ?? 'confirmed',
    enrolledAt: DateTime.tryParse(json['enrolled_at'] ?? '') ?? DateTime.now(),
  );
}
