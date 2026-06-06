// lib/features/sessions/presentation/screens/my_sessions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/sessions_repository.dart';

class MySessionsScreen extends ConsumerStatefulWidget {
  const MySessionsScreen({super.key});

  @override
  ConsumerState<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends ConsumerState<MySessionsScreen> {
  Map<String, dynamic> _history = {'as_tutee': [], 'as_tutor': []};
  bool _loading = true;
  int _tab = 0; // 0 = asesorado, 1 = tutor

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(sessionsRepositoryProvider).getHistory();
      if (mounted) setState(() { _history = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asTutee = List<dynamic>.from(_history['as_tutee'] ?? []);
    final asTutor = List<dynamic>.from(_history['as_tutor'] ?? []);
    final items = _tab == 0 ? asTutee : asTutor;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Mis Asesorias')),
      body: Column(children: [

        // Tabs
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            _TabBtn(
              label: 'Como asesorado',
              count: asTutee.length,
              active: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            const SizedBox(width: 10),
            _TabBtn(
              label: 'Como tutor',
              count: asTutor.length,
              active: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
          ]),
        ),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
              : items.isEmpty
                  ? EmptyState(
                      title: _tab == 0 ? 'Sin asesorias tomadas' : 'Sin asesorias publicadas',
                      description: _tab == 0
                          ? 'Explora y unete a asesorias disponibles'
                          : 'Crea tu primera asesoria',
                      action: _tab == 1
                          ? GreenButton(
                              label: 'Crear asesoria',
                              onPressed: () => context.push('/sessions/create'),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.ink,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          if (_tab == 0) {
                            return _TuteeSessionTile(enrollment: items[i]);
                          } else {
                            return _TutorSessionTile(session: items[i]);
                          }
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Tile para asesorado ───────────────────────────────────────
class _TuteeSessionTile extends StatelessWidget {
  final Map<String, dynamic> enrollment;
  const _TuteeSessionTile({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final session = enrollment['session'] as Map<String, dynamic>?;
    if (session == null) return const SizedBox.shrink();

    final status = session['status'] ?? '';
    final title = session['title'] ?? '';
    final subject = session['subject'] ?? '';
    final modality = session['modality'] ?? '';
    final scheduledAt = session['scheduled_at'] != null
        ? DateTime.tryParse(session['scheduled_at'])
        : null;
    final tutor = session['tutor'] as Map<String, dynamic>?;

    return AppCard(
      onTap: () => context.push('/sessions/${session['id']}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  letterSpacing: -0.3),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subject,
              style: const TextStyle(fontSize: 12, color: AppColors.green,
                  fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(width: 10),
          StatusTag(status),
        ]),

        const SizedBox(height: 10),

        Row(children: [
          if (tutor != null) ...[
            AppAvatar(
              name: tutor['full_name'] ?? '',
              imageUrl: tutor['avatar_url'],
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(tutor['full_name'] ?? '',
              style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
            const Spacer(),
          ],
          if (scheduledAt != null)
            Text(
              DateFormat('d MMM yyyy', 'es').format(scheduledAt),
              style: const TextStyle(fontSize: 11, color: AppColors.ink4),
            ),
        ]),

        // Calificar si esta completada
        if (status == 'completed') ...[
          const SizedBox(height: 10),
          const Divider(color: AppColors.line2, height: 1),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/sessions/${session['id']}'),
            child: Row(children: [
              const Icon(Icons.star_outline_rounded, size: 14, color: AppColors.amber),
              const SizedBox(width: 5),
              Text('Ver detalle y calificar',
                style: GoogleFonts.instrumentSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.amber)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.ink4),
            ]),
          ),
        ],

        // Tag virtual/presencial
        const SizedBox(height: 8),
        Row(children: [
          AppTag(modality == 'virtual' ? 'Virtual' : 'Presencial',
            color: modality == 'virtual' ? TagColor.blue : TagColor.green),
        ]),
      ]),
    );
  }
}

// ── Tile para tutor ───────────────────────────────────────────
class _TutorSessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  const _TutorSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final status = session['status'] ?? '';
    final title = session['title'] ?? '';
    final subject = session['subject'] ?? '';
    final modality = session['modality'] ?? '';
    final scheduledAt = session['scheduled_at'] != null
        ? DateTime.tryParse(session['scheduled_at'])
        : null;

    // Contar inscritos
    final enrollments = session['enrollments'];
    int enrolledCount = 0;
    if (enrollments is List) {
      enrolledCount = enrollments.length;
    } else if (enrollments is Map) {
      enrolledCount = (enrollments['count'] ?? 0) as int;
    }

    return AppCard(
      onTap: () => context.push('/sessions/${session['id']}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  letterSpacing: -0.3),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subject,
              style: const TextStyle(fontSize: 12, color: AppColors.green,
                  fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(width: 10),
          StatusTag(status),
        ]),

        const SizedBox(height: 10),

        Row(children: [
          const Icon(Icons.people_outline_rounded, size: 13, color: AppColors.ink4),
          const SizedBox(width: 4),
          Text('$enrolledCount inscritos',
            style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
          const Spacer(),
          if (scheduledAt != null)
            Text(
              DateFormat('d MMM yyyy', 'es').format(scheduledAt),
              style: const TextStyle(fontSize: 11, color: AppColors.ink4),
            ),
        ]),

        const SizedBox(height: 8),
        Row(children: [
          AppTag(modality == 'virtual' ? 'Virtual' : 'Presencial',
            color: modality == 'virtual' ? TagColor.blue : TagColor.green),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.ink4),
        ]),
      ]),
    );
  }
}

// ── Tab button ────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? AppColors.ink : AppColors.line,
          width: 1.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.instrumentSans(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? AppColors.surface : AppColors.ink3)),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.surface.withOpacity(0.2)
                  : AppColors.bg3,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: active ? AppColors.surface : AppColors.ink3)),
          ),
        ],
      ]),
    ),
  );
}
