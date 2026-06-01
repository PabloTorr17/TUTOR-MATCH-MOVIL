// lib/features/sessions/presentation/screens/sessions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/sessions_repository.dart';
import '../../domain/models/session_model.dart';
import '../../../auth/data/auth_repository.dart';

// ── SESSION CARD ──────────────────────────────────────────────
class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;

  const SessionCard({super.key, required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spotsLeft = session.availableSpots;
    final spotsPercent = session.maxSpots > 0
        ? ((session.maxSpots - spotsLeft) / session.maxSpots)
        : 0.0;

    return AppCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tags row
        Wrap(spacing: 6, runSpacing: 4, children: [
          AppTag(session.modalityLabel,
            color: session.modality == 'virtual' ? TagColor.blue : TagColor.green),
          AppTag(session.difficultyLabel),
          if (session.isFree) AppTag('GRATIS', color: TagColor.green),
          StatusTag(session.status),
        ]),

        const SizedBox(height: 10),

        // Title
        Text(session.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: -0.3),
          maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(session.subject,
          style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),

        const SizedBox(height: 8),

        // Description
        if (session.description.isNotEmpty)
          Text(session.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink3, height: 1.5),
            maxLines: 2, overflow: TextOverflow.ellipsis),

        const SizedBox(height: 10),

        // Meta info
        Wrap(spacing: 12, runSpacing: 4, children: [
          _MetaItem(Icons.calendar_today_rounded,
            DateFormat('d MMM yyyy', 'es').format(session.scheduledAt)),
          _MetaItem(Icons.access_time_rounded, _formatDuration(session.durationMinutes)),
          _MetaItem(Icons.people_outline_rounded, '$spotsLeft/${session.maxSpots} lugares'),
        ]),

        const SizedBox(height: 10),

        // Spots bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: spotsPercent.toDouble(),
            minHeight: 3,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(
              spotsLeft == 0 ? AppColors.red : spotsLeft <= 2 ? AppColors.amber : AppColors.green),
          ),
        ),

        const SizedBox(height: 12),

        // Footer: tutor + cost + action
        Row(children: [
          if (session.tutor != null) ...[
            AppAvatar(
              imageUrl: session.tutor!.avatarUrl,
              name: session.tutor!.fullName,
              size: 26,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(session.tutor!.fullName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (session.tutorProfile != null && session.tutorProfile!.rating > 0)
                  Row(children: [
                    StarRating(rating: session.tutorProfile!.rating, size: 10),
                    const SizedBox(width: 3),
                    Text(session.tutorProfile!.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 9, color: AppColors.amber, fontWeight: FontWeight.w700)),
                  ]),
              ]),
            ),
          ] else
            const Spacer(),
          const SizedBox(width: 8),
          CostText(cost: session.cost),
        ]),
      ]),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: AppColors.ink4),
    const SizedBox(width: 3),
    Text(text, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
  ]);
}

// ── SESSIONS SCREEN ───────────────────────────────────────────
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});
  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _modality = '';
  String _difficulty = '';
  String _type = '';
  List<SessionModel> _sessions = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loading && _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) { _page = 1; _hasMore = true; }
    setState(() => _loading = true);
    try {
      final repo = ref.read(sessionsRepositoryProvider);
      final results = await repo.getSessions(
        page: _page, limit: 10,
        search: _searchCtrl.text,
        modality: _modality, difficulty: _difficulty, sessionType: _type,
      );
      setState(() {
        if (reset) _sessions = results; else _sessions.addAll(results);
        _hasMore = results.length == 10;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    _page++;
    await _load();
  }

  void _applyFilter(String key, String val) {
    setState(() {
      if (key == 'modality') _modality = val;
      if (key == 'difficulty') _difficulty = val;
      if (key == 'type') _type = val;
    });
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Asesorias'),
        backgroundColor: AppColors.surface,
        actions: [
          if (auth.user?.isTutor == true)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Nueva'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => context.push('/sessions/create'),
              ),
            ),
        ],
      ),
      body: Column(children: [
        // Search + filters
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(children: [
            // Search bar
            TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(reset: true),
              decoration: InputDecoration(
                hintText: 'Buscar por materia, titulo...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.ink4),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.ink4),
                        onPressed: () { _searchCtrl.clear(); _load(reset: true); })
                    : null,
                filled: true,
                fillColor: AppColors.bg2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.ink, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterChip('Virtual', _modality == 'virtual', () => _applyFilter('modality', _modality == 'virtual' ? '' : 'virtual')),
                const SizedBox(width: 6),
                _FilterChip('Presencial', _modality == 'presential', () => _applyFilter('modality', _modality == 'presential' ? '' : 'presential')),
                const SizedBox(width: 6),
                _FilterChip('Basico', _difficulty == 'basic', () => _applyFilter('difficulty', _difficulty == 'basic' ? '' : 'basic')),
                const SizedBox(width: 6),
                _FilterChip('Intermedio', _difficulty == 'intermediate', () => _applyFilter('difficulty', _difficulty == 'intermediate' ? '' : 'intermediate')),
                const SizedBox(width: 6),
                _FilterChip('Avanzado', _difficulty == 'advanced', () => _applyFilter('difficulty', _difficulty == 'advanced' ? '' : 'advanced')),
                const SizedBox(width: 6),
                _FilterChip('Grupal', _type == 'group', () => _applyFilter('type', _type == 'group' ? '' : 'group')),
                const SizedBox(width: 6),
                _FilterChip('Rapida', _type == 'quick', () => _applyFilter('type', _type == 'quick' ? '' : 'quick')),
              ]),
            ),
          ]),
        ),

        // List
        Expanded(
          child: _loading && _sessions.isEmpty
              ? ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => _SessionSkeleton(),
                )
              : _sessions.isEmpty
                  ? EmptyState(
                      title: 'Sin asesorias',
                      description: 'Intenta otros filtros o busca otra materia',
                      action: auth.user?.isTutor == true
                          ? GreenButton(label: 'Crear la primera', onPressed: () => context.push('/sessions/create'))
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(reset: true),
                      color: AppColors.ink,
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          if (i == _sessions.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                              ),
                            );
                          }
                          final s = _sessions[i];
                          return SessionCard(
                            session: s,
                            onTap: () => context.push('/sessions/${s.id}'),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: selected ? AppColors.ink : AppColors.line, width: 1.5),
      ),
      child: Text(label, style: GoogleFonts.instrumentSans(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: selected ? AppColors.surface : AppColors.ink3)),
    ),
  );
}

class _SessionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.line, width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [SkeletonBox(width: 70, height: 18), const SizedBox(width: 6), SkeletonBox(width: 80, height: 18)]),
      const SizedBox(height: 10),
      SkeletonBox(width: double.infinity, height: 16),
      const SizedBox(height: 6),
      SkeletonBox(width: 120, height: 12),
      const SizedBox(height: 12),
      SkeletonBox(width: double.infinity, height: 10),
      const SizedBox(height: 4),
      SkeletonBox(width: 200, height: 10),
    ]),
  );
}
