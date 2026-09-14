import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme tokens — import this in all intro pages and onboarding_screen.
class AppTheme {
  AppTheme._();

  // ── Colors ───────────────────────────────────────────────────────────
  static const Color background  = Color(0xFF0F1E1B); // dark teal-green bg
  static const Color cardBg      = Color(0xFF162320); // slightly lighter card surface
  static const Color cardBorder  = Color(0xFF1F3530); // subtle card border
  static const Color accent      = Color(0xFF0D9E7A); // teal CTA / highlights
  static const Color accentLight = Color(0xFF1DB890); // lighter teal for italic text

  static const Color textPrimary   = Color(0xFFE8F5F1); // near-white body text
  static const Color textSecondary = Color(0xFF7AB5A6); // muted paragraph text
  static const Color textEyebrow   = Color(0xFF0D9E7A); // uppercase label

  // Status colors (ingredient ratings)
  static const Color safe   = Color(0xFF27AE60);
  static const Color safeBg = Color(0xFF0D2E20);
  static const Color warn   = Color(0xFFE67E22);
  static const Color warnBg = Color(0xFF2A1800);
  static const Color bad    = Color(0xFFE74C3C);
  static const Color badBg  = Color(0xFF2A0E0E);

  // ── Text Styles ──────────────────────────────────────────────────────

  /// Small uppercase eyebrow — "FOOD INTELLIGENCE"
  static TextStyle get eyebrow => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: textEyebrow,
  );

  /// Main heading — bold sans
  static TextStyle get heading => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: textPrimary,
  );

  /// Italic serif accent word inside heading — "really", "additives", "today"
  static TextStyle get headingAccent => GoogleFonts.dmSerifDisplay(
    fontStyle: FontStyle.italic,
    fontSize: 30,
    fontWeight: FontWeight.w400,
    color: accentLight,
  );

  /// Body paragraph
  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: 15,
    height: 1.65,
    color: textSecondary,
  );

  /// Small label inside cards / pills
  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // ── ThemeData ────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: cardBg,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
  );
}
