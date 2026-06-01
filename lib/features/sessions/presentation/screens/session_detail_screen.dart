// lib/features/sessions/presentation/screens/session_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/sessions_repository.dart';
import '../../domain/models/session_model.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../payment/data/payment_repository.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  SessionModel? _session;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  int _reviewRating = 5;
  final _reviewCtrl = TextEditingController();
  bool _reviewSent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = await ref.read(sessionsRepositoryProvider).getSessionById(widget.sessionId);
      setState(() { _session = session; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error cargando asesoria'; _loading = false; });
    }
  }

  // ── ENROLL LOGIC (free or paid) ────────────────────────────
  Future<void> _handleEnroll() async {
    if (_session == null) return;
    setState(() { _actionLoading = true; _error = null; });

    try {
      if (_session!.isFree) {
        // Gratis: inscribir directamente
        await ref.read(paymentRepositoryProvider).enrollFree(_session!.id);
        _showSuccess('Inscripcion exitosa');
      } else {
        // Pago: crear PaymentIntent y abrir hoja de Stripe
        final payRepo = ref.read(paymentRepositoryProvider);
        final clientSecret = await payRepo.createPaymentIntent(
          sessionId: _session!.id,
          amount: _session!.cost,
        );
        await payRepo.processPaymentAndEnroll(
          sessionId: _session!.id,
          clientSecret: clientSecret,
        );
        _showSuccess('Pago exitoso. Inscripcion confirmada');
      }
      await _load(); // Recargar para actualizar estado
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Cancelled') || msg.contains('cancelled')) {
        // Usuario cancelo el pago, no es error
      } else {
        setState(() => _error = _parseError(e));
      }
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleUnenroll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cancelar inscripcion', style: Theme.of(context).textTheme.titleLarge),
        content: Text('Deseas cancelar tu inscripcion en esta asesoria?',
          style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Si, cancelar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(sessionsRepositoryProvider).unenroll(_session!.id);
      await _load();
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleStatusChange(String status) async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(sessionsRepositoryProvider).updateStatus(_session!.id, status);
      await _load();
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _sendReview() async {
    try {
      await ref.read(sessionsRepositoryProvider).createReview(
        sessionId: _session!.id,
        rating: _reviewRating,
        comment: _reviewCtrl.text,
      );
      setState(() => _reviewSent = true);
      _showSuccess('Resena publicada');
    } catch (e) {
      setState(() => _error = _parseError(e));
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  String _parseError(dynamic e) {
    try { return e.response?.data?['message'] ?? e.toString(); }
    catch (_) { return e.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Detalle'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
          : _session == null
              ? EmptyState(title: 'Asesoria no encontrada', action: AppOutlineButton(label: 'Volver', onPressed: () => context.pop()))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = _session!;
    final user = ref.watch(authProvider).user;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.ink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 14)],

          // ── Header card ──
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 4, children: [
              AppTag(s.modalityLabel, color: s.modality == 'virtual' ? TagColor.blue : TagColor.green),
              AppTag(s.difficultyLabel),
              if (s.isFree) AppTag('GRATIS', color: TagColor.green),
              StatusTag(s.status),
            ]),
            const SizedBox(height: 12),
            Text(s.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(s.subject, style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
            if (s.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(s.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink3, height: 1.6)),
            ],
            if (s.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 4, children: s.tags.map((t) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.line)),
                  child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
                )
              ).toList()),
            ],
          ])),

          const SizedBox(height: 12),

          // ── Details card ──
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Detalles', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _DetailRow('Fecha', DateFormat('EEEE d MMM yyyy', 'es').format(s.scheduledAt)),
            _DetailRow('Hora', DateFormat('hh:mm a').format(s.scheduledAt)),
            _DetailRow('Duracion', _formatDuration(s.durationMinutes)),
            _DetailRow('Modalidad', s.modalityLabel),
            _DetailRow('Cupos', '${s.availableSpots} de ${s.maxSpots} disponibles'),
            _DetailRow('Tipo', s.sessionType),
            if (s.modality == 'presential' && s.location != null)
              _DetailRow('Ubicacion', s.location!),
            if (s.modality == 'virtual' && s.isEnrolled && s.meetLink != null)
              _DetailRow('Enlace', s.meetLink!, isLink: true),
          ])),

          const SizedBox(height: 12),

          // ── Tutor card ──
          if (s.tutor != null)
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionLabel('Tutor'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/users/${s.tutorId}'),
                child: Row(children: [
                  AppAvatar(imageUrl: s.tutor!.avatarUrl, name: s.tutor!.fullName, size: 48),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.tutor!.fullName, style: Theme.of(context).textTheme.titleLarge),
                    Text('${s.tutor!.career} · ${s.tutor!.semester}° Sem.',
                      style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                    if (s.tutorProfile != null && s.tutorProfile!.rating > 0) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        StarRating(rating: s.tutorProfile!.rating, size: 12),
                        const SizedBox(width: 4),
                        Text(s.tutorProfile!.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber)),
                        const SizedBox(width: 4),
                        Text('(${s.tutorProfile!.totalSessions} ses.)',
                          style: const TextStyle(fontSize: 10, color: AppColors.ink4)),
                      ]),
                    ],
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.ink4),
                ]),
              ),
            ])),

          const SizedBox(height: 12),

          // ── Action card ──
          AppCard(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Costo', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink4)),
              CostText(cost: s.cost, fontSize: 28),
            ]),
            const SizedBox(height: 6),
            Text('${s.availableSpots} lugar${s.availableSpots != 1 ? "es" : ""} disponible${s.availableSpots != 1 ? "s" : ""}',
              style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
            const SizedBox(height: 16),

            // Not owner actions
            if (!s.isOwner) ...[
              if (!s.isEnrolled && s.isAvailable) ...[
                // Enroll / Pay button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _actionLoading ? null : _handleEnroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.isFree ? AppColors.ink : AppColors.green,
                      foregroundColor: s.isFree ? AppColors.surface : AppColors.ink,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _actionLoading
                        ? SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2,
                              color: s.isFree ? AppColors.surface : AppColors.ink))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            if (!s.isFree) ...[
                              const Icon(Icons.lock_rounded, size: 15),
                              const SizedBox(width: 6),
                            ],
                            Text(s.isFree ? 'Inscribirme' : 'Pagar e inscribirme',
                              style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w700)),
                          ]),
                  ),
                ),
                // Stripe badge for paid
                if (!s.isFree) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.ink4),
                    const SizedBox(width: 4),
                    Text('Pago seguro via Stripe',
                      style: GoogleFonts.instrumentSans(fontSize: 10, color: AppColors.ink4)),
                  ]),
                ],
              ],

              if (s.isEnrolled) ...[
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.greenDim, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green.withOpacity(0.3)),
                  ),
                  child: Center(child: Text('Inscrito',
                    style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF009944)))),
                ),
                const SizedBox(height: 8),
                AppOutlineButton(label: 'Cancelar inscripcion', onPressed: _actionLoading ? null : _handleUnenroll),
              ],

              if (!s.isEnrolled && !s.isAvailable && s.status == 'full')
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: AppColors.amberDim, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('Sin lugares disponibles',
                    style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.amber))),
                ),
            ],

            // Owner controls
            if (s.isOwner) ...[
              const SectionLabel('Controles del tutor'),
              const SizedBox(height: 10),
              if (s.status == 'available')
                PrimaryButton(label: 'Iniciar asesoria', loading: _actionLoading,
                  onPressed: () => _handleStatusChange('in_progress')),
              if (s.status == 'in_progress')
                GreenButton(label: 'Marcar completada', loading: _actionLoading,
                  onPressed: () => _handleStatusChange('completed')),
              if (['available', 'in_progress'].contains(s.status)) ...[
                const SizedBox(height: 8),
                AppOutlineButton(label: 'Cancelar asesoria',
                  onPressed: _actionLoading ? null : () => _handleStatusChange('cancelled')),
              ],
            ],
          ])),

          // ── Review form ──
          if (s.isEnrolled && s.status == 'completed' && !_reviewSent) ...[
            const SizedBox(height: 12),
            AppCard(
              backgroundColor: AppColors.greenDim,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Califica esta asesoria',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF007A3D))),
                const SizedBox(height: 14),
                Row(children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => _reviewRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i < _reviewRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 32, color: i < _reviewRating ? AppColors.amber : AppColors.line),
                  ),
                ))),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Comparte tu experiencia con este tutor...',
                    filled: true, fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Publicar resena', onPressed: _sendReview),
              ]),
            ),
          ],

          if (_reviewSent) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greenDim, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Text('Resena enviada. Gracias!',
                style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF007A3D)),
                textAlign: TextAlign.center),
            ),
          ],

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLink;
  const _DetailRow(this.label, this.value, {this.isLink = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 90,
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink4, fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: isLink
            ? GestureDetector(
                onTap: () => launchUrl(Uri.parse(value)),
                child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.blue, decoration: TextDecoration.underline)),
              )
            : Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink2, fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}
