import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Premium Dark Navy Theme
  static const Color primary = Color(0xFF3E61E4); // Electric blue accent
  static const Color primaryLight = Color(0xFF5E7DF5); 
  static const Color primaryDark = Color(0xFF2B47AD); 
  
  static const Color accent = Color(0xFF3E61E4); 
  static const Color background = Color(0xFF111218); // Deep navy background
  static const Color bgGradientStart = Color(0xFF111218); 
  static const Color bgGradientEnd = Color(0xFF161822); 
  
  static const Color surface = Color(0xFF1C1E26); // Glassmorphic card surface
  static const Color darkSurface = Color(0xFF1C1E26); 
  static const Color border = Color(0xFF292C38); // Subtle border
  
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFF7E8299); // Muted blue-grey
  static const Color textTertiary = Color(0xFF525668); // Darker muted text

  // Health semantics (matching the dark theme aesthetic)
  static const Color heartRate = Color(0xFFFF4D6D); // soft neon red
  static const Color hrv = Color(0xFF34C759); // green
  static const Color sleep = Color(0xFF8A6FFF); // soft purple
  static const Color activity = Color(0xFFFF9500); // orange
  static const Color spo2 = Color(0xFF32ADE6); // cyan
  static const Color temperature = Color(0xFFFF2D55); // pink
  static const Color stress = Color(0xFF5E5CE6); // indigo

  // Status
  static const Color success = Color(0xFF34C759); 
  static const Color warning = Color(0xFFFF9500); 
  static const Color danger = Color(0xFFFF4D6D); 
  static const Color info = Color(0xFF3E61E4); 

  // Card specific translucent configurations
  static const Color glassCardBackground = Color(0x991C1E26); // Translucent surface
  static const Color glassCardBorder = Color(0x33FFFFFF); // subtle light border
  static const Color darkCard = Color(0xFF1C1E26);

  // Backwards compatibility for existing screens
  static const Color surfaceDark = darkSurface;
  static const Color surfaceDark2 = Color(0xFF242633);
  static const Color borderDark = border;
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;

  static Color adaptiveTextPrimary(Brightness brightness) => textPrimary; // Always dark theme now
  static Color adaptiveTextSecondary(Brightness brightness) => textSecondary;
  static Color adaptiveSurface(Brightness brightness) => surface;
}
