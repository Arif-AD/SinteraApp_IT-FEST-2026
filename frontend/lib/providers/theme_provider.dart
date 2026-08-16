import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current [ThemeMode] for the application.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
