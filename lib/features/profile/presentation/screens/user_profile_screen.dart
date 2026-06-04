// lib/features/profile/presentation/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final responses = await Future.wait([
        ApiClient().get('/users/${widget.userId}'),
        ApiClient().get('/reviews/tutor/${widget.userId}'),
      ]);
      setState(() {
        _profile = responses[0].data['data'];
        _reviews = responses[1].data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar el perfil';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Perfil del tutor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.ink3)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = _profile!;
    final profile = p['profile'] as Map<String, dynamic>?;
    final roles = List<String>.from(p['roles'] ?? []);
    final subjects = List<String>.from(profile?['subjects'] ?? []);
    final rating = (profile?['rating'] ?? 0).toDouble();
    final totalSessions = profile?['total_sessions'] ?? 0;
    final attendanceRate = (profile?['attendance_rate'] ?? 100).toDouble();
    final bio = profile?['bio'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AppAvatar(
              imageUrl: p['avatar_url'],
              name: p['full_name'] ?? '',
              size: 64,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['full_name'] ?? '',
                style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 3),
              Text('${p['career'] ?? ''} · ${p['semester'] ?? ''}° Sem.',
                style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
              const SizedBox(height: 6),
              Wrap(spacing: 5, children: roles.map((r) => AppTag(r,
                color: r == 'tutor' ? TagColor.green
                     : r == 'admin' ? TagColor.amber
                     : TagColor.defaultTag,
              )).toList()),
            ])),
          ]),

          if (bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.line),
            const SizedBox(height: 14),
            Text(bio,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.ink3, height: 1.6)),
          ],
        ])),

        const SizedBox(height: 12),

        // Stats
        Row(children: [
          _StatCard(
            value: rating > 0 ? rating.toStringAsFixed(1) : 'N/A',
            label: 'Rating',
            accent: rating > 0,
          ),
          const SizedBox(width: 10),
          _StatCard(value: '$totalSessions', label: 'Asesorias'),
          const SizedBox(width: 10),
          _StatCard(value: '${attendanceRate.toInt()}%', label: 'Asistencia'),
        ]),

        const SizedBox(height: 12),

        // Materias
        if (subjects.isNotEmpty)
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Materias que domina'),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: subjects.map((s) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
              )
            ).toList()),
          ])),

        if (subjects.isNotEmpty) const SizedBox(height: 12),

        // Resenas
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SectionLabel('Resenas'),
            if (rating > 0) Row(children: [
              StarRating(rating: rating, size: 13),
              const SizedBox(width: 5),
              Text(rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber)),
            ]),
          ]),
          const SizedBox(height: 12),

          if (_reviews.isEmpty)
            const Text('Sin resenas aun',
              style: TextStyle(fontSize: 13, color: AppColors.ink4))
          else
            ...(_reviews.take(5).map((r) => _ReviewTile(review: r))),
        ])),

        const SizedBox(height: 32),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const _StatCard({
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: accent ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent ? AppColors.ink : AppColors.line,
          width: 1.5,
        ),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.bebasNeue(
          fontSize: 28,
          color: accent ? AppColors.green : AppColors.ink,
          letterSpacing: 1,
        )),
        Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: accent ? AppColors.surface.withOpacity(0.5) : AppColors.ink4,
          letterSpacing: 0.5,
        )),
      ]),
    ),
  );
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review['reviewer'] as Map<String, dynamic>?;
    final rating = (review['rating'] ?? 0).toInt();
    final comment = review['comment'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppAvatar(
            name: reviewer?['full_name'] ?? '',
            imageUrl: reviewer?['avatar_url'],
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reviewer?['full_name'] ?? 'Anonimo',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            StarRating(rating: rating.toDouble(), size: 11),
          ])),
        ]),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(comment,
            style: const TextStyle(fontSize: 12, color: AppColors.ink3, height: 1.5)),
        ],
        const SizedBox(height: 10),
        const Divider(color: AppColors.line2, height: 1),
      ]),
    );
  }
}
