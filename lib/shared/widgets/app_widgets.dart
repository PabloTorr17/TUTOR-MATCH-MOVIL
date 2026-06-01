// lib/shared/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

// ── TAG BADGE ─────────────────────────────────────────────────
enum TagColor { defaultTag, green, red, amber, blue, ink }

class AppTag extends StatelessWidget {
  final String label;
  final TagColor color;

  const AppTag(this.label, {super.key, this.color = TagColor.defaultTag});

  @override
  Widget build(BuildContext context) {
    final colors = {
      TagColor.defaultTag: (AppColors.bg3, AppColors.ink3, AppColors.line),
      TagColor.green: (AppColors.greenDim, const Color(0xFF009944), AppColors.green),
      TagColor.red: (AppColors.redDim, AppColors.red, AppColors.red),
      TagColor.amber: (AppColors.amberDim, AppColors.amber, AppColors.amber),
      TagColor.blue: (AppColors.blueDim, AppColors.blue, AppColors.blue),
      TagColor.ink: (AppColors.ink, AppColors.surface, AppColors.ink),
    }[color]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.$3.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.instrumentSans(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: colors.$2, letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── STATUS TAG ────────────────────────────────────────────────
class StatusTag extends StatelessWidget {
  final String status;
  const StatusTag(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final config = {
      'available':   ('DISPONIBLE', TagColor.green),
      'full':        ('LLENO',       TagColor.amber),
      'in_progress': ('EN CURSO',    TagColor.blue),
      'completed':   ('COMPLETADA',  TagColor.defaultTag),
      'cancelled':   ('CANCELADA',   TagColor.red),
    }[status] ?? (status.toUpperCase(), TagColor.defaultTag);

    return AppTag(config.$1, color: config.$2);
  }
}

// ── AVATAR ────────────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const AppAvatar({super.key, this.imageUrl, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final hue = name.isNotEmpty ? (name.codeUnitAt(0) * 37 % 360).toDouble() : 200.0;
    final bgColor = HSLColor.fromAHSL(1, hue, 0.55, 0.88).toColor();
    final fgColor = HSLColor.fromAHSL(1, hue, 0.55, 0.25).toColor();

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: AppColors.line2, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Initials(initials, fgColor, size))
          : _Initials(initials, fgColor, size),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  const _Initials(this.text, this.color, this.size);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text.isEmpty ? '?' : text,
      style: GoogleFonts.instrumentSans(
        fontSize: size * 0.35, fontWeight: FontWeight.w700, color: color,
      )),
  );
}

// ── STARS ─────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: i < rating.round() ? AppColors.amber : AppColors.line,
      )),
    );
  }
}

// ── PRIMARY BUTTON ────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.ink;
    final fg = foregroundColor ?? AppColors.surface;

    final btn = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg, foregroundColor: fg,
        minimumSize: fullWidth ? const Size(double.infinity, 48) : const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: loading
          ? SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg))
          : Text(label, style: GoogleFonts.instrumentSans(
              fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
    );

    return fullWidth ? btn : btn;
  }
}

// ── GREEN BUTTON ──────────────────────────────────────────────
class GreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const GreenButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) => PrimaryButton(
    label: label, onPressed: onPressed, loading: loading,
    backgroundColor: AppColors.green, foregroundColor: AppColors.ink,
  );
}

// ── OUTLINE BUTTON ────────────────────────────────────────────
class AppOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppOutlineButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: AppColors.line, width: 1.5),
    ),
    child: Text(label, style: GoogleFonts.instrumentSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
  );
}

// ── APP CARD ──────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const AppCard({super.key, required this.child, this.onTap, this.padding, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── SECTION LABEL ─────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: GoogleFonts.instrumentSans(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: AppColors.ink4, letterSpacing: 0.8,
    ),
  );
}

// ── SHIMMER SKELETON ──────────────────────────────────────────
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, required this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.bg3,
    highlightColor: AppColors.bg2,
    child: Container(
      width: width, height: height,
      decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(radius)),
    ),
  );
}

// ── EMPTY STATE ───────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? action;

  const EmptyState({super.key, required this.title, this.description, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.bg3, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line, width: 1.5),
          ),
          child: const Icon(Icons.search_off_rounded, color: AppColors.ink4, size: 24),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        if (description != null) ...[
          const SizedBox(height: 6),
          Text(description!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    ),
  );
}

// ── ERROR BANNER ──────────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.redDim,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.red.withOpacity(0.3)),
    ),
    child: Text(message, style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.red)),
  );
}

// ── COST DISPLAY ──────────────────────────────────────────────
class CostText extends StatelessWidget {
  final double cost;
  final double fontSize;

  const CostText({super.key, required this.cost, this.fontSize = 15});

  @override
  Widget build(BuildContext context) => Text(
    cost == 0 ? 'Gratis' : '\$${cost.toStringAsFixed(0)} MXN',
    style: GoogleFonts.bebasNeue(
      fontSize: fontSize, letterSpacing: 0.5,
      color: cost == 0 ? AppColors.green : AppColors.ink,
    ),
  );
}
