// lib/features/sessions/data/sessions_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/models/session_model.dart';

class SessionsRepository {
  final ApiClient _api = ApiClient();

  Future<List<SessionModel>> getSessions({
    int page = 1,
    int limit = 10,
    String? subject,
    String? modality,
    String? difficulty,
    String? sessionType,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (subject != null && subject.isNotEmpty) params['subject'] = subject;
    if (modality != null && modality.isNotEmpty) params['modality'] = modality;
    if (difficulty != null && difficulty.isNotEmpty) params['difficulty'] = difficulty;
    if (sessionType != null && sessionType.isNotEmpty) params['session_type'] = sessionType;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _api.get('/sessions', params: params);
    final List data = response.data['data'] ?? [];
    return data.map((j) => SessionModel.fromJson(j)).toList();
  }

  Future<SessionModel> getSessionById(String id) async {
    final response = await _api.get('/sessions/$id');
    return SessionModel.fromJson(response.data['data']);
  }

  Future<SessionModel> createSession(Map<String, dynamic> data) async {
    final response = await _api.post('/sessions', data: data);
    return SessionModel.fromJson(response.data['data']);
  }

  Future<EnrollmentModel> enroll(String sessionId) async {
    final response = await _api.post('/sessions/$sessionId/enroll');
    return EnrollmentModel.fromJson(response.data['data']);
  }

  Future<void> unenroll(String sessionId) async {
    await _api.delete('/sessions/$sessionId/enroll');
  }

  Future<SessionModel> updateStatus(String sessionId, String status) async {
    final response = await _api.patch('/sessions/$sessionId/status', data: {'status': status});
    return SessionModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> getHistory() async {
    final response = await _api.get('/users/me/history');
    return response.data['data'];
  }

  Future<List<SessionModel>> getFavorites() async {
    final response = await _api.get('/users/me/favorites');
    final List data = response.data['data'] ?? [];
    return data.map((j) => SessionModel.fromJson(j)).toList();
  }

  Future<bool> toggleFavorite(String sessionId) async {
    final response = await _api.post('/users/me/favorites/$sessionId');
    return response.data['data']['favorited'] ?? false;
  }

  Future<void> createReview({
    required String sessionId,
    required int rating,
    String? comment,
  }) async {
    await _api.post('/reviews', data: {
      'session_id': sessionId,
      'rating': rating,
      'comment': comment ?? '',
    });
  }
}

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) => SessionsRepository());
