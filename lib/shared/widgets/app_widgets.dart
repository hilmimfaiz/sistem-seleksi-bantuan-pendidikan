import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aplikasi_finansialpendidikan/core/constants/app_colors.dart';

// ===== APP BUTTON =====

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;
  final double? width;
  final LinearGradient? gradient;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
    this.width,
    this.gradient,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child;

    if (widget.isOutlined) {
      child = OutlinedButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: widget.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              )
            : (widget.icon != null ? Icon(widget.icon, size: 18) : const SizedBox.shrink()),
        label: Text(widget.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } else {
      final effectiveGradient = widget.gradient ?? AppColors.primaryGradient;
      final disabled = widget.isLoading || widget.onPressed == null;
      
      child = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: disabled ? null : effectiveGradient,
          color: disabled ? (isDark ? AppColors.darkSurfaceVariant : AppColors.outline) : null,
          boxShadow: disabled ? [] : [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: widget.isLoading ? null : widget.onPressed,
          icon: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : (widget.icon != null ? Icon(widget.icon, size: 18, color: Colors.white) : const SizedBox.shrink()),
          label: Text(widget.label, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: 54, // Modern taller buttons
          child: child,
        ),
      ),
    );
  }
}

// ===== APP TEXT FIELD =====

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? initialValue;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixWidget,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = false;
  late FocusNode _internalNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _internalNode = widget.focusNode ?? FocusNode();
    _internalNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _internalNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        maxLines: _obscure ? 1 : widget.maxLines,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        focusNode: _internalNode,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: 20, color: _isFocused ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textTertiary))
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : widget.suffixWidget,
        ),
      ),
    );
  }
}

// ===== LOADING SHIMMER =====

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.height = 60,
    this.width,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.darkOutline : AppColors.surface,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkOutline : AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerLoading(height: 48, width: 48, borderRadius: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLoading(height: 16, width: 120),
                  SizedBox(height: 8),
                  ShimmerLoading(height: 12, width: 80),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          const ShimmerLoading(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          const ShimmerLoading(height: 14, width: 200),
        ],
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) => const ShimmerCard()
          .animate()
          .fade(duration: 400.ms, delay: (index * 100).ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}

// ===== EMPTY STATE =====

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 32),
              action!,
            ],
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack),
    );
  }
}

// ===== ERROR STATE =====

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_rounded,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Terjadi Kesalahan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Coba Lagi',
                onPressed: onRetry,
                width: 180,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

// ===== STATUS BADGE =====

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'MENUNGGU': return AppColors.statusMenunggu;
      case 'REVISI': return AppColors.statusRevisi;
      case 'DITOLAK': return AppColors.statusDitolak;
      case 'TERVERIFIKASI': return AppColors.statusTerverifikasi;
      case 'SELEKSI': return AppColors.statusSeleksi;
      case 'DITERIMA': return AppColors.statusDiterima;
      case 'TIDAK_DITERIMA': return AppColors.statusTidakDiterima;
      case 'AKTIF': return AppColors.success;
      case 'TIDAK_AKTIF': return AppColors.textTertiary;
      case 'LAYAK': return AppColors.success;
      case 'TIDAK_LAYAK': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (status.toUpperCase()) {
      case 'MENUNGGU': return 'Menunggu';
      case 'REVISI': return 'Perlu Revisi';
      case 'DITOLAK': return 'Ditolak';
      case 'TERVERIFIKASI': return 'Terverifikasi';
      case 'SELEKSI': return 'Seleksi';
      case 'DITERIMA': return 'Diterima';
      case 'TIDAK_DITERIMA': return 'Tidak Diterima';
      case 'AKTIF': return 'Aktif';
      case 'TIDAK_AKTIF': return 'Tidak Aktif';
      case 'LAYAK': return 'Layak';
      case 'TIDAK_LAYAK': return 'Tidak Layak';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== CATEGORY BADGE =====

class KategoriBadge extends StatelessWidget {
  final String kategori;

  const KategoriBadge({super.key, required this.kategori});

  Color get _color {
    switch (kategori.toUpperCase()) {
      case 'SANGAT_MEMBUTUHKAN': return AppColors.sangatMembutuhkan;
      case 'MEMBUTUHKAN': return AppColors.membutuhkan;
      case 'CUKUP_MAMPU': return AppColors.cukupMampu;
      case 'MAMPU': return AppColors.mampu;
      case 'OUTLIER': return AppColors.outlier;
      default: return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (kategori.toUpperCase()) {
      case 'SANGAT_MEMBUTUHKAN': return 'Sangat Membutuhkan';
      case 'MEMBUTUHKAN': return 'Membutuhkan';
      case 'CUKUP_MAMPU': return 'Cukup Mampu';
      case 'MAMPU': return 'Mampu';
      case 'OUTLIER': return 'Outlier';
      default: return kategori;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ===== INFO CARD (Modern Statistic Card) =====

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final LinearGradient? gradient;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.primaryGradient;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppColors.primary).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Icon(Icons.arrow_outward_rounded, color: Colors.white.withOpacity(0.5), size: 20),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
