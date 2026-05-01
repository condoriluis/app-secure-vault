import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/core/color_theme.dart';
import 'package:secure_vault/providers/theme_provider.dart';

class ColorThemePicker extends ConsumerWidget {
  const ColorThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final selectedThemeId = themeState.colorThemeId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12, top: 8),
          child: Text(
            'Paleta de Colores',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ColorThemes.all.length,
            itemBuilder: (context, index) {
              final colorTheme = ColorThemes.all[index];
              final isSelected = colorTheme.id == selectedThemeId;

              return _ColorThemeOption(
                colorTheme: colorTheme,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () {
                  ref.read(themeProvider.notifier).setColorTheme(colorTheme.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColorThemeOption extends StatefulWidget {
  final ColorThemeData colorTheme;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ColorThemeOption({
    required this.colorTheme,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ColorThemeOption> createState() => _ColorThemeOptionState();
}

class _ColorThemeOptionState extends State<_ColorThemeOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = widget.isDark
        ? widget.colorTheme.darkPrimary
        : widget.colorTheme.lightPrimary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 45,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Color Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [displayColor, displayColor.withOpacity(0.7)],
                  ),
                  border: Border.all(
                    color: widget.isSelected
                        ? (widget.isDark ? Colors.white : Colors.black)
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withOpacity(0.4),
                      blurRadius: widget.isSelected ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: _getContrastColor(displayColor),
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              // Theme Name
              Text(
                widget.colorTheme.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: widget.isDark
                      ? (widget.isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7))
                      : (widget.isSelected
                            ? Colors.black87
                            : Colors.grey.shade600),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
