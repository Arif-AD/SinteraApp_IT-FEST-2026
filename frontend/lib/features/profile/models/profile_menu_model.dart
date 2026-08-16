import 'package:flutter/material.dart';

class ProfileMenuModel {
  const ProfileMenuModel({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}