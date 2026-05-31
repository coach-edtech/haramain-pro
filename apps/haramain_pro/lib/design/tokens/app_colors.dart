import 'package:flutter/material.dart';

/// Haramain Pro Color System
/// Inspired by "Kemewahan Tanah Suci" - Luxury Islamic aesthetic
/// Deep emerald greens, warm gold accents, sacred cream tones
class AppColors {
  AppColors._();

  // ========================================================================
  // PRIMARY: Deep Emerald — Headers, primary actions
  // ========================================================================
  static const Color emerald900 = Color(0xFF064e3b); // Primary dark, headers
  static const Color emerald700 = Color(0xFF047857); // Primary base
  static const Color emerald500 = Color(0xFF10b981); // Interactive elements
  static const Color emerald400 = Color(0xFF34d399); // Lighter emerald
  static const Color emerald300 = Color(0xFF6ee7b7); // Light emerald
  static const Color emerald200 = Color(0xFFa7f3d0); // Subtle emerald (used in dark bg contexts)
  static const Color emerald100 = Color(0xFFd1fae5); // Subtle backgrounds

  // Legacy aliases for existing code
  static const Color primaryLight = emerald900;
  static const Color primaryDark = emerald900;

  // ========================================================================
  // ACCENT: Gold — CTAs, highlights, sacred elements
  // ========================================================================
  static const Color amber500 = Color(0xFFf59e0b); // Primary accent, CTAs
  static const Color amber400 = Color(0xFFfbbf24); // Hover states
  static const Color amber600 = Color(0xFFd97706); // Active states
  static const Color amber50 = Color(0xFFfffbeb); // Warm background tints

  // Legacy aliases
  static const Color gold = amber500;
  static const Color goldLight = amber400;
  static const Color goldDark = amber600;

  // ========================================================================
  // DANGER: Panic Red — Emergency, critical actions
  // ========================================================================
  static const Color red600 = Color(0xFFdc2626); // Panic button
  static const Color red500 = Color(0xFFef4444); // Panic hover
  static const Color red100 = Color(0xFFfee2e2); // Alert backgrounds
  static const Color red900 = Color(0xFF7f1d1d); // Deep panic
  static const Color emerald600 = Color(0xFF059669); // Emerald for success states

  // Legacy aliases
  static const Color error = red600;
  static const Color errorDark = red500;

  // ========================================================================
  // NEUTRAL: Slate — Text, borders, surfaces
  // ========================================================================
  static const Color slate900 = Color(0xFF0f172a); // Text primary
  static const Color slate800 = Color(0xFF1e293b); // Text dark
  static const Color slate700 = Color(0xFF334155); // Text secondary dark
  static const Color slate600 = Color(0xFF475569); // Text secondary
  static const Color slate500 = Color(0xFF64748b); // Text muted
  static const Color slate400 = Color(0xFF94a3b8); // Text disabled
  static const Color slate300 = Color(0xFFcbd5e1); // Borders light
  static const Color slate200 = Color(0xFFe2e8f0); // Borders
  static const Color slate100 = Color(0xFFf1f5f9); // Subtle backgrounds
  static const Color slate50 = Color(0xFFf8fafc); // Page background

  // Legacy aliases
  static const Color onSurfaceLight = slate900;
  static const Color onSurfaceDark = Color(0xFFf8fafc);
  static const Color onBackgroundLight = slate900;
  static const Color onBackgroundDark = Color(0xFFe0e0e0);

  // ========================================================================
  // SURFACE: Light theme
  // ========================================================================
  static const Color surfaceLight = Color(0xFFF8F6F3);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0D0D0D);
  static const Color backgroundDark = Color(0xFF121212);

  // ========================================================================
  // LEGACY COMPATIBILITY
  // ========================================================================
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFFFB74D);
  static const Color success = emerald500;
  static const Color info = Color(0xFF64B5F6);

  static const Color dividerLight = slate200;
  static const Color dividerDark = Color(0xFF2D2D2D);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A1A1A);

  static const Color shimmerLight = Color(0xFFE0E0E0);
  static const Color shimmerDark = Color(0xFF2D2D2D);

  // ========================================================================
  // ARABIC TEXTURE: Sacred warmth
  // ========================================================================
  static const Color cream = Color(0xFFfef9e7); // Alternative warm surface
  static const Color darkNavy = Color(0xFF0c1929); // Alternate dark theme
}
