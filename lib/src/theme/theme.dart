import 'package:flutter/material.dart';

/// Semantic colors shared by every Flappa component.
@immutable
class FColors {
  const FColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.ring,
  });

  factory FColors.zinc({Brightness brightness = Brightness.light}) =>
      brightness == Brightness.light
      ? const FColors(
          background: Color(0xFFFFFFFF),
          foreground: Color(0xFF09090B),
          card: Color(0xFFFFFFFF),
          primary: Color(0xFF18181B),
          primaryForeground: Color(0xFFFAFAFA),
          secondary: Color(0xFFF4F4F5),
          secondaryForeground: Color(0xFF18181B),
          muted: Color(0xFFF4F4F5),
          mutedForeground: Color(0xFF71717A),
          accent: Color(0xFFF4F4F5),
          accentForeground: Color(0xFF18181B),
          destructive: Color(0xFFDC2626),
          destructiveForeground: Color(0xFFFFFFFF),
          border: Color(0xFFE4E4E7),
          ring: Color(0xFFA1A1AA),
        )
      : const FColors(
          background: Color(0xFF09090B),
          foreground: Color(0xFFFAFAFA),
          card: Color(0xFF111113),
          primary: Color(0xFFFAFAFA),
          primaryForeground: Color(0xFF18181B),
          secondary: Color(0xFF27272A),
          secondaryForeground: Color(0xFFFAFAFA),
          muted: Color(0xFF27272A),
          mutedForeground: Color(0xFFA1A1AA),
          accent: Color(0xFF27272A),
          accentForeground: Color(0xFFFAFAFA),
          destructive: Color(0xFFEF4444),
          destructiveForeground: Color(0xFFFFFFFF),
          border: Color(0xFF27272A),
          ring: Color(0xFF71717A),
        );

  final Color background, foreground, card, primary, primaryForeground;
  final Color secondary, secondaryForeground, muted, mutedForeground;
  final Color accent, accentForeground, destructive, destructiveForeground;
  final Color border, ring;

  FColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? ring,
  }) => FColors(
    background: background ?? this.background,
    foreground: foreground ?? this.foreground,
    card: card ?? this.card,
    primary: primary ?? this.primary,
    primaryForeground: primaryForeground ?? this.primaryForeground,
    secondary: secondary ?? this.secondary,
    secondaryForeground: secondaryForeground ?? this.secondaryForeground,
    muted: muted ?? this.muted,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    accent: accent ?? this.accent,
    accentForeground: accentForeground ?? this.accentForeground,
    destructive: destructive ?? this.destructive,
    destructiveForeground: destructiveForeground ?? this.destructiveForeground,
    border: border ?? this.border,
    ring: ring ?? this.ring,
  );

  static FColors lerp(FColors a, FColors b, double t) => FColors(
    background: Color.lerp(a.background, b.background, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
    card: Color.lerp(a.card, b.card, t)!,
    primary: Color.lerp(a.primary, b.primary, t)!,
    primaryForeground: Color.lerp(a.primaryForeground, b.primaryForeground, t)!,
    secondary: Color.lerp(a.secondary, b.secondary, t)!,
    secondaryForeground: Color.lerp(
      a.secondaryForeground,
      b.secondaryForeground,
      t,
    )!,
    muted: Color.lerp(a.muted, b.muted, t)!,
    mutedForeground: Color.lerp(a.mutedForeground, b.mutedForeground, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
    accentForeground: Color.lerp(a.accentForeground, b.accentForeground, t)!,
    destructive: Color.lerp(a.destructive, b.destructive, t)!,
    destructiveForeground: Color.lerp(
      a.destructiveForeground,
      b.destructiveForeground,
      t,
    )!,
    border: Color.lerp(a.border, b.border, t)!,
    ring: Color.lerp(a.ring, b.ring, t)!,
  );
}

/// Install with [toThemeData] on a MaterialApp, or use [FlappaApp].
@immutable
class FThemeData extends ThemeExtension<FThemeData> {
  FThemeData({
    this.brightness = Brightness.light,
    FColors? colors,
    this.radius = 8,
    this.fontFamily,
  }) : colors = colors ?? FColors.zinc(brightness: brightness),
       assert(radius >= 0);

  final Brightness brightness;
  final FColors colors;
  final double radius;
  final String? fontFamily;
  BorderRadius get borderRadius => BorderRadius.circular(radius);

  @override
  FThemeData copyWith({
    Brightness? brightness,
    FColors? colors,
    double? radius,
    String? fontFamily,
  }) => FThemeData(
    brightness: brightness ?? this.brightness,
    colors:
        colors ??
        (brightness != null && brightness != this.brightness
            ? FColors.zinc(brightness: brightness)
            : this.colors),
    radius: radius ?? this.radius,
    fontFamily: fontFamily ?? this.fontFamily,
  );

  @override
  FThemeData lerp(covariant FThemeData? other, double t) {
    if (other == null) return this;
    return FThemeData(
      brightness: t < .5 ? brightness : other.brightness,
      colors: FColors.lerp(colors, other.colors, t),
      radius: radius + (other.radius - radius) * t,
      fontFamily: t < .5 ? fontFamily : other.fontFamily,
    );
  }

  ThemeData toThemeData() {
    final c = colors;
    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: c.border),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: c.background,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: c.primary,
            brightness: brightness,
          ).copyWith(
            primary: c.primary,
            onPrimary: c.primaryForeground,
            secondary: c.secondary,
            onSecondary: c.secondaryForeground,
            surface: c.background,
            onSurface: c.foreground,
            error: c.destructive,
            onError: c.destructiveForeground,
            outline: c.border,
            outlineVariant: c.border,
            surfaceTint: Colors.transparent,
          ),
      extensions: [this],
      splashFactory: NoSplash.splashFactory,
      dividerColor: c.border,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: .2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.background,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: c.mutedForeground, fontSize: 14),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: c.ring, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: c.destructive),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: c.destructive, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: c.border),
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primaryForeground
              : c.background,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.primary : c.muted,
        ),
        trackOutlineColor: WidgetStatePropertyAll(c.border),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.muted,
        thumbColor: c.primary,
        trackHeight: 5,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.muted,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.foreground,
          borderRadius: borderRadius,
        ),
        textStyle: TextStyle(color: c.background, fontSize: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: c.border),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

abstract final class FTheme {
  static FThemeData of(BuildContext context) =>
      Theme.of(context).extension<FThemeData>() ??
      FThemeData(brightness: Theme.of(context).brightness);
}

/// Convenient application root. For routing/localization use MaterialApp directly
/// with `theme: FThemeData().toThemeData()`.
class FlappaApp extends StatelessWidget {
  const FlappaApp({
    super.key,
    required this.home,
    this.title = 'Flappa',
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.debugShowCheckedModeBanner = false,
  });
  final Widget home;
  final String title;
  final FThemeData? theme, darkTheme;
  final ThemeMode themeMode;
  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: title,
    theme: (theme ?? FThemeData()).toThemeData(),
    darkTheme: (darkTheme ?? FThemeData(brightness: Brightness.dark))
        .toThemeData(),
    themeMode: themeMode,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    home: home,
  );
}
