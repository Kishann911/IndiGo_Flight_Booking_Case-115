import 'package:flutter/material.dart';

import 'models/fare_family.dart';
import 'models/flight_tracking.dart';
import 'models/seat.dart';

/// Brand and semantic colours (generic indigo palette, no airline branding).
class AppColors {
  AppColors._();

  static const brand = Color(0xFF2A2F8F);

  static const lite = Color(0xFF00796B);
  static const classic = Color(0xFF3949AB);
  static const flex = Color(0xFFB45309);

  static const tierXl = Color(0xFF7B1FA2);
  static const tierFront = Color(0xFF1565C0);
  static const tierStandard = Color(0xFF2E7D32);
  static const tierMiddle = Color(0xFF7CB342);
  static const seatOccupied = Color(0xFFBDBDBD);

  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFE65100);
  static const danger = Color(0xFFC62828);

  static Color fare(FareFamily f) => switch (f) {
        FareFamily.lite => lite,
        FareFamily.classic => classic,
        FareFamily.flex => flex,
      };

  static Color tier(SeatTier t) => switch (t) {
        SeatTier.xl => tierXl,
        SeatTier.front => tierFront,
        SeatTier.standard => tierStandard,
        SeatTier.standardMiddle => tierMiddle,
      };

  static Color status(FlightStatus s) => switch (s) {
        FlightStatus.scheduled => const Color(0xFF1565C0),
        FlightStatus.boarding => const Color(0xFF6A1B9A),
        FlightStatus.departed || FlightStatus.enRoute => brand,
        FlightStatus.landed => success,
        FlightStatus.delayed => warning,
        FlightStatus.cancelled => danger,
      };
}

/// Spacing scale (logical px).
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppTheme {
  AppTheme._();

  /// Max width of page content on wide web.
  static const double maxContentWidth = 1100;
  static const double radius = 16;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.brand, brightness: b).copyWith(
      primary: b == Brightness.light ? AppColors.brand : null,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
    final t = base.textTheme;
    final text = t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 2),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
        margin: const EdgeInsets.symmetric(vertical: AppSpace.s / 2),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      navigationBarTheme: NavigationBarThemeData(indicatorColor: scheme.primaryContainer),
      navigationRailTheme: NavigationRailThemeData(indicatorColor: scheme.primaryContainer),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
