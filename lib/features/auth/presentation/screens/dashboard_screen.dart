// lib/features/auth/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../sessions/data/sessions_repository.dart';
import '../../../sessions/domain/models/session_model.dart';
import '../../../sessions/presentation/screens/sessions_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<SessionModel> _sessions = [];
  Map<String, dynamic> _history = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(sessionsRepositoryProvider);
      final results = await Future.wait([
        repo.getSessions(limit: 5),
        repo.getHistory(),
      ]);
      setState(() {
        _sessions = results[0] as List<SessionModel>;
        _history = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final tuteeHistory = (_history['as_tutee'] as List? ?? []);
    final tutorHistory = (_history['as_tutor'] as List? ?? []);
    final completed = tuteeHistory.where((e) => e['session']?['status'] == 'completed').length
        + tutorHistory.where((s) => s['status'] == 'completed').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.ink,
        child: CustomScrollView(slivers: [
          // Header
          SliverToBoxAdapter(child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                DateFormat('EEEE d MMM', 'es').format(DateTime.now()).toUpperCase(),
                style: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink4, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'HOLA, ', style: GoogleFonts.bebasNeue(fontSize: 36, color: AppColors.ink, letterSpacing: 2)),
                TextSpan(text: user.firstName.toUpperCase(), style: GoogleFonts.bebasNeue(fontSize: 36, color: AppColors.green, letterSpacing: 2,
                  shadows: [Shadow(color: AppColors.green.withOpacity(0.3), blurRadius: 12)])),
              ])),
              Row(children: [
                Text('${user.career.split(' ').first}', style: const TextStyle(fontSize: 13, color: AppColors.ink3)),
                const Text(' · ', style: TextStyle(color: AppColors.line)),
                Text('${user.semester}° Semestre', style: const TextStyle(fontSize: 13, color: AppColors.ink3)),
              ]),
              const SizedBox(height: 16),
              // Role chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: user.isTutor ? AppColors.greenDim : AppColors.bg2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: user.isTutor ? AppColors.green.withOpacity(0.4) : AppColors.line, width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.isTutor ? AppColors.green : AppColors.ink4,
                  )),
                  const SizedBox(width: 6),
                  Text(
                    user.isTutor ? 'TUTOR ACTIVO' : 'ASESORADO',
                    style: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w700,
                      color: user.isTutor ? const Color(0xFF007A3D) : AppColors.ink4, letterSpacing: 0.8),
                  ),
                ]),
              ),
            ]),
          )),

          // Stats
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              _BigStat(value: '${tuteeHistory.length}', label: 'Tomadas', green: true),
              const SizedBox(width: 10),
              _BigStat(value: '$completed', label: 'Completadas'),
              const SizedBox(width: 10),
              _BigStat(value: '${user.semester}°', label: 'Semestre'),
              if (user.isTutor) ...[
                const SizedBox(width: 10),
                _BigStat(value: '${tutorHistory.length}', label: 'Publicadas'),
              ],
            ]),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Quick actions
          if (user.isTutor) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => context.push('/sessions/create'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.green.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.ink, size: 20),
                  const SizedBox(width: 10),
                  Text('PUBLICAR NUEVA ASESORIA',
                    style: GoogleFonts.bebasNeue(fontSize: 18, color: AppColors.ink, letterSpacing: 1.5)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.ink, size: 18),
                ]),
              ),
            ),
          )),

          if (user.isTutor) const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Upcoming sessions header
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Disponibles', style: Theme.of(context).textTheme.headlineSmall),
              GestureDetector(
                onTap: () => context.go('/sessions'),
                child: Text('Ver todas', style: GoogleFonts.instrumentSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink3,
                  decoration: TextDecoration.underline)),
              ),
            ]),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Sessions list
          _loading
              ? SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, i < 2 ? 10 : 0),
                    child: _SessionSkeleton(),
                  ), childCount: 3))
              : _sessions.isEmpty
                  ? SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppCard(child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('Sin asesorias disponibles',
                            style: Theme.of(context).textTheme.bodySmall),
                        ),
                      )),
                    ))
                  : SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, i < _sessions.length - 1 ? 10 : 0),
                        child: SessionCard(
                          session: _sessions[i],
                          onTap: () => context.push('/sessions/${_sessions[i].id}'),
                        ),
                      ),
                      childCount: _sessions.length,
                    )),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  final bool green;
  const _BigStat({required this.value, required this.label, this.green = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: green ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: green ? AppColors.ink : AppColors.line, width: 1.5),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.bebasNeue(
          fontSize: 32, color: green ? AppColors.green : AppColors.ink, letterSpacing: 1,
        )),
        Text(label, style: GoogleFonts.instrumentSans(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: green ? AppColors.surface.withOpacity(0.5) : AppColors.ink4,
          letterSpacing: 0.5,
        ), textAlign: TextAlign.center),
      ]),
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
    ]),
  );
}
