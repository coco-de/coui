import 'package:coui_flutter/coui_flutter.dart';

/// Theme data for customizing [Card] and [SurfaceCard] widget appearance.
///
/// This class defines the visual properties that can be applied to card widgets,
/// including padding, fill behavior, colors, borders, shadows, and surface effects.
/// These properties can be set at the theme level to provide consistent styling
/// across the application.
///
/// The theme affects both regular cards and surface cards, with surface cards
/// supporting additional blur and opacity effects for glassmorphism styling.
class CardTheme {
  /// Creates a [CardTheme].
  const CardTheme({
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.boxShadow,
    this.clipBehavior,
    this.duration,
    this.fillColor,
    this.filled,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  /// Padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Whether the card is filled.
  final bool? filled;

  /// The fill color when [filled] is true.
  final Color? fillColor;

  /// Border radius of the card.
  final BorderRadiusGeometry? borderRadius;

  /// Border color of the card.
  final Color? borderColor;

  /// Border width of the card.
  final double? borderWidth;

  /// Clip behavior of the card.
  final Clip? clipBehavior;

  /// Box shadow of the card.
  final List<BoxShadow>? boxShadow;

  /// Surface opacity for blurred background.
  final double? surfaceOpacity;

  /// Surface blur for blurred background.
  final double? surfaceBlur;

  /// Animation duration for transitions.
  final Duration? duration;

  /// Creates a copy of this theme with the given values replaced.
  CardTheme copyWith({
    ValueGetter<Color?>? borderColor,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<double?>? borderWidth,
    ValueGetter<List<BoxShadow>?>? boxShadow,
    ValueGetter<Clip?>? clipBehavior,
    ValueGetter<Duration?>? duration,
    ValueGetter<Color?>? fillColor,
    ValueGetter<bool?>? filled,
    ValueGetter<EdgeInsetsGeometry?>? padding,
    ValueGetter<double?>? surfaceBlur,
    ValueGetter<double?>? surfaceOpacity,
  }) {
    return CardTheme(
      borderColor: borderColor == null ? this.borderColor : borderColor(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      borderWidth: borderWidth == null ? this.borderWidth : borderWidth(),
      boxShadow: boxShadow == null ? this.boxShadow : boxShadow(),
      clipBehavior: clipBehavior == null ? this.clipBehavior : clipBehavior(),
      duration: duration == null ? this.duration : duration(),
      fillColor: fillColor == null ? this.fillColor : fillColor(),
      filled: filled == null ? this.filled : filled(),
      padding: padding == null ? this.padding : padding(),
      surfaceBlur: surfaceBlur == null ? this.surfaceBlur : surfaceBlur(),
      surfaceOpacity:
          surfaceOpacity == null ? this.surfaceOpacity : surfaceOpacity(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CardTheme &&
        other.padding == padding &&
        other.filled == filled &&
        other.fillColor == fillColor &&
        other.borderRadius == borderRadius &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.clipBehavior == clipBehavior &&
        other.boxShadow == boxShadow &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(
        padding,
        filled,
        fillColor,
        borderRadius,
        borderColor,
        borderWidth,
        clipBehavior,
        boxShadow,
        surfaceOpacity,
        surfaceBlur,
        duration,
      );
}

/// A versatile container widget that provides a card-like appearance with comprehensive styling options.
///
/// [Card] is a foundational layout component that wraps content in a visually distinct
/// container with configurable borders, shadows, fills, and surface effects. It serves
/// as the basis for many UI patterns including content cards, panels, sections, and
/// grouped information displays.
///
/// Key features:
/// - Flexible fill and border styling options
/// - Configurable shadow effects for depth perception
/// - Customizable corner radius and clipping behavior
/// - Surface effects for glassmorphism and blur styling
/// - Responsive padding with theme integration
/// - Animation support for state transitions
/// - Consistent theming across the application
///
/// The card supports various visual modes:
/// - Filled cards with solid background colors
/// - Outlined cards with transparent backgrounds and borders
/// - Surface cards with blur effects and opacity
/// - Elevated cards with shadow effects
/// - Custom combinations of fill, border, and shadow
///
/// Visual hierarchy can be achieved through:
/// - Shadow depth for elevation indication
/// - Fill colors for emphasis and categorization
/// - Border styles for subtle grouping
/// - Surface effects for modern glass-like appearances
///
/// Example:
/// ```dart
/// Card(
///   filled: true,
///   fillColor: Colors.white,
///   borderRadius: BorderRadius.circular(12),
///   boxShadow: [
///     BoxShadow(
///       color: Colors.black.withOpacity(0.1),
///       blurRadius: 8,
///       offset: Offset(0, 2),
///     ),
///   ],
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Column(
///       children: [
///         Text('Card Title', style: TextStyle(fontWeight: FontWeight.bold)),
///         SizedBox(height: 8),
///         Text('Card content goes here...'),
///       ],
///     ),
///   ),
/// );
/// ```
class Card extends StatelessWidget {
  const Card({
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.boxShadow,
    required this.child,
    this.clipBehavior,
    this.duration,
    this.fillColor,
    this.filled,
    super.key,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool? filled;
  final Color? fillColor;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final Clip? clipBehavior;
  final List<BoxShadow>? boxShadow;
  final double? surfaceOpacity;
  final double? surfaceBlur;

  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<CardTheme>(context);
    final scaling = theme.scaling;
    final padding = styleValue(
      defaultValue: EdgeInsets.all(scaling * 16),
      themeValue: compTheme?.padding,
      widgetValue: this.padding,
    );
    final filled = styleValue(
      defaultValue: false,
      themeValue: compTheme?.filled,
      widgetValue: this.filled,
    );
    final fillColor = styleValue(
      defaultValue: theme.colorScheme.border,
      themeValue: compTheme?.fillColor,
      widgetValue: this.fillColor,
    );
    final borderRadius = styleValue(
      defaultValue: null,
      themeValue: compTheme?.borderRadius,
      widgetValue: this.borderRadius,
    );
    final borderColor = styleValue(
      defaultValue: null,
      themeValue: compTheme?.borderColor,
      widgetValue: this.borderColor,
    );
    final borderWidth = styleValue(
      defaultValue: null,
      themeValue: compTheme?.borderWidth,
      widgetValue: this.borderWidth,
    );
    final clipBehavior = styleValue(
      defaultValue: Clip.none,
      themeValue: compTheme?.clipBehavior,
      widgetValue: this.clipBehavior,
    );
    final boxShadow = styleValue(
      defaultValue: null,
      themeValue: compTheme?.boxShadow,
      widgetValue: this.boxShadow,
    );
    final surfaceOpacity = styleValue(
      defaultValue: null,
      themeValue: compTheme?.surfaceOpacity,
      widgetValue: this.surfaceOpacity,
    );
    final surfaceBlur = styleValue(
      defaultValue: null,
      themeValue: compTheme?.surfaceBlur,
      widgetValue: this.surfaceBlur,
    );
    final duration = styleValue(
      defaultValue: null,
      themeValue: compTheme?.duration,
      widgetValue: this.duration,
    );

    return OutlinedContainer(
      backgroundColor: filled ? fillColor : theme.colorScheme.card,
      borderColor: borderColor,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      boxShadow: boxShadow,
      clipBehavior: clipBehavior,
      duration: duration,
      padding: padding,
      surfaceBlur: surfaceBlur,
      surfaceOpacity: surfaceOpacity,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.colorScheme.cardForeground),
        child: child,
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.boxShadow,
    required this.child,
    this.clipBehavior,
    this.duration,
    this.fillColor,
    this.filled,
    super.key,
    this.padding,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool? filled;
  final Color? fillColor;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final Clip? clipBehavior;
  final List<BoxShadow>? boxShadow;
  final double? surfaceOpacity;
  final double? surfaceBlur;

  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<CardTheme>(context);
    final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(context);
    final scaling = theme.scaling;
    if (isSheetOverlay) {
      final padding = styleValue(
        defaultValue: EdgeInsets.all(scaling * 16),
        themeValue: compTheme?.padding,
        widgetValue: this.padding,
      );

      return Padding(padding: padding, child: child);
    }

    return Card(
      borderColor: borderColor,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      boxShadow: boxShadow,
      clipBehavior: clipBehavior,
      duration: duration ?? compTheme?.duration,
      fillColor: fillColor,
      filled: filled,
      padding: padding,
      surfaceBlur: surfaceBlur ?? compTheme?.surfaceBlur ?? theme.surfaceBlur,
      surfaceOpacity:
          surfaceOpacity ?? compTheme?.surfaceOpacity ?? theme.surfaceOpacity,
      child: child,
    );
  }
}
