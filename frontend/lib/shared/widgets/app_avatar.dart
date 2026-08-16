import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Circular profile avatar that renders the user's initials.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.imageUrl,
    this.onTap,
  });

  final String name;
  final double size;
  final String? imageUrl;
  final VoidCallback? onTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E7D32),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsText,
              ),
            )
          : _initialsText,
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: avatar,
    );
  }

  Widget get _initialsText => Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: AppColors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
