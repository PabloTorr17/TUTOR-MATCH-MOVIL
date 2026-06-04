// lib/features/sessions/presentation/screens/create_session_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../sessions/data/sessions_repository.dart';

const _subjects = [
  'Cálculo Diferencial', 'Cálculo Integral', 'Álgebra Lineal',
  'Probabilidad y Estadística', 'Programación Orientada a Objetos',
  'Estructuras de Datos', 'Bases de Datos', 'Algoritmos y Complejidad',
  'Redes de Computadoras', 'Sistemas Operativos', 'Desarrollo Web',
  'Inteligencia Artificial', 'Física I', 'Física II',
  'Química General', 'Inglés Técnico', 'Ética Profesional',
  'Administración de Proyectos',
];

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _meetCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _tagsCtrl        = TextEditingController();

  String  _subject       = _subjects.first;
  String  _modality      = 'virtual';
  String  _difficulty    = 'intermediate';
  String  _sessionType   = 'scheduled';
  int     _durationMin   = 60;
  int     _maxSpots      = 1;
  double  _cost          = 0;
  DateTime _scheduledAt  = DateTime.now().add(const Duration(days: 1))
      .copyWith(hour: 10, minute: 0, second: 0, millisecond: 0);
  bool    _loading       = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _meetCtrl.dispose();
    _locationCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.ink),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.ink),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final payload = {
        'title':            _titleCtrl.text.trim(),
        'subject':          _subject,
        'description':      _descCtrl.text.trim(),
        'modality':         _modality,
        'meet_link':        _modality == 'virtual' ? _meetCtrl.text.trim() : null,
        'location':         _modality == 'presential' ? _locationCtrl.text.trim() : null,
        'scheduled_at':     _scheduledAt.toUtc().toIso8601String(),
        'duration_minutes': _durationMin,
        'max_spots':        _maxSpots,
        'cost':             _cost,
        'difficulty':       _difficulty,
        'session_type':     _sessionType,
        'tags':             tags,
      };

      final session = await ref.read(sessionsRepositoryProvider).createSession(payload);

      if (!mounted) return;
      context.push('/sessions/${session.id}');
    } catch (e) {
      setState(() {
        try {
          _error = (e as dynamic).response?.data?['message'] ?? e.toString();
        } catch (_) {
          _error = e.toString();
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nueva Asesoria'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _loading ? null : _submit,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: _loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                  : Text('Publicar',
                      style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 14),
            ],

            // ── Informacion basica ──
            _SectionTitle('Informacion basica'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Titulo *'),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Minimo 5 caracteres' : null,
            ),
            const SizedBox(height: 12),

            // Subject dropdown
            _FieldLabel('Materia *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(),
              style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink),
              items: _subjects.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _subject = v); },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripcion',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Etiquetas (separadas por coma)',
                hintText: 'calculo, derivadas, mate',
              ),
            ),

            const SizedBox(height: 24),

            // ── Modalidad ──
            _SectionTitle('Modalidad'),
            const SizedBox(height: 12),

            Row(children: [
              _ModalityBtn('Virtual', 'virtual', Icons.videocam_outlined),
              const SizedBox(width: 10),
              _ModalityBtn('Presencial', 'presential', Icons.location_on_outlined),
            ]),
            const SizedBox(height: 12),

            if (_modality == 'virtual')
              TextFormField(
                controller: _meetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Enlace de reunion *',
                  hintText: 'https://meet.google.com/...',
                ),
                validator: (v) => _modality == 'virtual' && (v == null || v.trim().isEmpty)
                    ? 'El enlace es requerido' : null,
              )
            else
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ubicacion *',
                  hintText: 'Biblioteca Central, Mesa 5',
                ),
                validator: (v) => _modality == 'presential' && (v == null || v.trim().isEmpty)
                    ? 'La ubicacion es requerida' : null,
              ),

            const SizedBox(height: 24),

            // ── Fecha y hora ──
            _SectionTitle('Fecha y hora'),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.line, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.ink3),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    DateFormat('EEEE d MMM yyyy  •  HH:mm', 'es').format(_scheduledAt),
                    style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink),
                  )),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.ink4),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            _FieldLabel('Duracion'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _durationMin,
              decoration: const InputDecoration(),
              style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink),
              items: const [
                DropdownMenuItem(value: 30,  child: Text('30 minutos')),
                DropdownMenuItem(value: 45,  child: Text('45 minutos')),
                DropdownMenuItem(value: 60,  child: Text('1 hora')),
                DropdownMenuItem(value: 90,  child: Text('1.5 horas')),
                DropdownMenuItem(value: 120, child: Text('2 horas')),
                DropdownMenuItem(value: 180, child: Text('3 horas')),
              ],
              onChanged: (v) { if (v != null) setState(() => _durationMin = v); },
            ),

            const SizedBox(height: 24),

            // ── Configuracion ──
            _SectionTitle('Configuracion'),
            const SizedBox(height: 12),

            _FieldLabel('Dificultad'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(),
              style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink),
              items: const [
                DropdownMenuItem(value: 'basic',        child: Text('Basico')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermedio')),
                DropdownMenuItem(value: 'advanced',     child: Text('Avanzado')),
                DropdownMenuItem(value: 'any',          child: Text('Cualquier nivel')),
              ],
              onChanged: (v) { if (v != null) setState(() => _difficulty = v); },
            ),
            const SizedBox(height: 12),

            _FieldLabel('Tipo de sesion'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _sessionType,
              decoration: const InputDecoration(),
              style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink),
              items: const [
                DropdownMenuItem(value: 'scheduled', child: Text('Programada')),
                DropdownMenuItem(value: 'individual', child: Text('Individual')),
                DropdownMenuItem(value: 'group',      child: Text('Grupal')),
              ],
              onChanged: (v) { if (v != null) setState(() => _sessionType = v); },
            ),
            const SizedBox(height: 12),

            // Cupos
            _FieldLabel('Cupos: $_maxSpots'),
            Slider(
              value: _maxSpots.toDouble(),
              min: 1, max: 20, divisions: 19,
              activeColor: AppColors.ink,
              inactiveColor: AppColors.line,
              thumbColor: AppColors.ink,
              label: '$_maxSpots',
              onChanged: (v) => setState(() => _maxSpots = v.round()),
            ),
            const SizedBox(height: 12),

            // Costo
            _FieldLabel('Costo (MXN): ${_cost == 0 ? "Gratis" : "\$${_cost.toStringAsFixed(0)}"}'),
            Slider(
              value: _cost,
              min: 0, max: 500, divisions: 50,
              activeColor: _cost == 0 ? AppColors.green : AppColors.ink,
              inactiveColor: AppColors.line,
              thumbColor: _cost == 0 ? AppColors.green : AppColors.ink,
              label: _cost == 0 ? 'Gratis' : '\$${_cost.toStringAsFixed(0)}',
              onChanged: (v) => setState(() => _cost = v),
            ),

            const SizedBox(height: 32),

            // Preview card
            AppCard(
              backgroundColor: AppColors.bg2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionLabel('Vista previa'),
                const SizedBox(height: 10),
                Text(
                  _titleCtrl.text.isEmpty ? 'Sin titulo aun' : _titleCtrl.text,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 3),
                Text(_subject, style: const TextStyle(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(children: [
                  Text(_modality == 'virtual' ? 'Virtual' : 'Presencial',
                    style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                  const Text('  ·  ', style: TextStyle(color: AppColors.line)),
                  Text('$_maxSpots cupo${_maxSpots != 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                  const Text('  ·  ', style: TextStyle(color: AppColors.line)),
                  Text(_cost == 0 ? 'Gratis' : '\$${_cost.toStringAsFixed(0)} MXN',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _cost == 0 ? AppColors.green : AppColors.ink)),
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            PrimaryButton(
              label: 'Publicar asesoria',
              loading: _loading,
              onPressed: _submit,
            ),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _ModalityBtn(String label, String value, IconData icon) {
    final selected = _modality == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modality = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? AppColors.surface : AppColors.ink3),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.instrumentSans(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? AppColors.surface : AppColors.ink3)),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text.toUpperCase(), style: GoogleFonts.instrumentSans(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: AppColors.ink4, letterSpacing: 0.8)),
      const SizedBox(height: 4),
      const Divider(color: AppColors.line, thickness: 1.5, height: 1),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.instrumentSans(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.ink3, letterSpacing: 0.5));
}
