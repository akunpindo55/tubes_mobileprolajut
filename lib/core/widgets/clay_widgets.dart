import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ClayContainer extends StatelessWidget {
  final Widget? child;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final List<BoxShadow>? boxShadows;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const ClayContainer({
    super.key,
    this.child,
    required this.color,
    this.borderRadius = 20.0,
    this.borderWidth = 3.0,
    this.borderColor = AppColors.border,
    this.boxShadows,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: boxShadows ?? [
          // Outer shadow (soft, dark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          // Inner highlight simulation
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            offset: const Offset(-2, -2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class ClayButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const ClayButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = AppColors.babyBlue,
    this.borderRadius = 24.0,
    this.borderWidth = 3.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: AppColors.border, width: widget.borderWidth),
            boxShadow: _isPressed
                ? [
                    // Deeper inner shadow when pressed
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    // Fluffy outer shadow when floating
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(4, 4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      offset: const Offset(-2, -2),
                      blurRadius: 3,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            child: Center(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class ClayTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const ClayTextField({
    super.key,
    this.controller,
    required this.label,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        ClayContainer(
          color: Colors.white,
          borderRadius: 20,
          borderWidth: 3.0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: AppColors.textDark, fontSize: 16),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
              border: InputBorder.none,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textMuted, size: 22)
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
