// This demo file intentionally uses equal width/height for square UI elements
// and equal offsets for corner positioning.

// Demo widgets naturally have long build methods due to comprehensive examples.

// Parameter lists are descriptive for demo clarity.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:coui_widgetbook/preview/surface_preview.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'component_demo.stories.g.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

/// Base size constants used across the demo - eliminates duplicate values.
abstract final class _Size {
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s36 = 36.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s60 = 60.0;
  static const s80 = 80.0;
  static const s120 = 120.0;
}

/// Theme generation constants for color and radius calculations.
abstract final class _ThemeConstants {
  static const maxHue = 360.0;
  static const lightModeBaseLightness = 0.65;
  static const darkModeBaseLightness = 0.7;
  static const lightModeBaseChroma = 0.18;
  static const darkModeBaseChroma = 0.15;
  static const triadicHueOffset = 120.0;
  static const complementaryHueOffset = 180.0;
  static const analogousHueOffset = 30.0;
  static const secondaryChromaRatio = 0.8;
  static const accentChromaRatio = 0.9;

  // Base color lightness values (dark mode).
  static const darkBase100Lightness = 20;
  static const darkBase200Lightness = 25;
  static const darkBase300Lightness = 30;
  static const darkNeutralLightness = 40;
  static const darkBaseContentLightness = 95;

  // Base color lightness values (light mode).
  static const lightBase100Lightness = 99;
  static const lightBase200Lightness = 96;
  static const lightBase300Lightness = 92;
  static const lightNeutralLightness = 70;
  static const int lightBaseContentLightness = darkBase100Lightness;
}

/// CoUI component demo layout constants.
abstract final class _DemoConstants {
  // Each card needs 300 logical pixels including its inner padding. Columns
  // are derived from the remaining preview width, not the browser window.
  static const minCardWidth = 300.0;
  static const cardSpacing = 16.0;
  static const double cardPadding = cardSpacing;
  static const cardRadius = 12.0;
}

// =============================================================================
// ENUMS
// =============================================================================

/// Color harmony modes for theme generation.
enum ColorHarmony {
  /// Analogous color scheme with 30° hue shifts.
  analogous('Analogous'),

  /// Complementary color scheme with 180° opposite hues.
  complementary('Complementary'),

  /// Monochromatic scheme with same hue, varying saturation.
  monochromatic('Monochromatic'),

  /// Triadic color scheme with 120° hue shifts.
  triadic('Triadic'),
  ;

  const ColorHarmony(this.displayName);

  /// Display name shown in the UI.
  final String displayName;
}

// =============================================================================
/// Chroma values for theme generation.
abstract final class _ChromaValues {
  static const darkMode = 0.02;
  static const lightModeHigh = 0.005;
  static const lightModeLow = 0.01;
  static const lightnessThreshold = 90;
}

/// Demo knob and data values.
abstract final class _DemoData {
  static const initialHue = 265.0;
  static const defaultRadius = 8.0;
  static const luminanceThreshold = 0.5;
  static const mobileColumnCount = 1;
  static const desktopColumnCount = 3;
}

/// Opacity values used across the demo.
abstract final class _Opacity {
  static const half = 0.5;
  static const faded = 0.7;
  static const subtle = 0.15;
}

/// Semantic content colors for status indicators.
abstract final class _SemanticContentColors {
  static const darkContent = Color(0xFF000000);
  static const lightContent = Color(0xFFFFFFFF);
}

/// Filter demo item count values.
abstract final class _FilterCounts {
  static const hoodies = 25;
  static const bags = 3;
  static const shoes = 8;
  static const accessories = 4;
}

/// Stats chart bar heights (fractional).
///
/// Each bar uses a distinct fractional height so the demo chart shows a
/// varied silhouette.
abstract final class _ChartHeights {
  static const barCount = 12;

  static const values = [
    0.3,
    0.5,
    0.4,
    0.62,
    0.8,
    0.7,
    0.9,
    0.65,
    0.72,
    0.55,
    0.82,
    0.6,
  ];
}

/// Demo content values for i18n functions.
abstract final class _DemoValues {
  static const newMessageCount = 9;
  static const reviewCount = 420;
  static const priceSmall = 120;
  static const priceMedium = 150;
  static const priceLarge = 200;
  static const maxCharacters = 1200;

  /// Default value shown for slider demos (mid-point of the 0..1 range).
  static const sliderValue = 0.5;
}

// THEME GENERATION
// =============================================================================

/// Caches generated themes to avoid expensive recomputation on knob changes.
abstract final class _ThemeCache {
  static final _cache = <int, ThemeData>{};

  static ThemeData getOrGenerate({
    required double primaryHue,
    required ColorHarmony harmonyMode,
    required bool isDarkMode,
    required double radiusScale,
  }) {
    final key = Object.hash(
      primaryHue.round(),
      harmonyMode,
      isDarkMode,
      radiusScale.round(),
    );

    // Cache mutation is intentional for memoization.
    return _cache.putIfAbsent(
      key,
      () => _generateCustomTheme(
        primaryHue: primaryHue,
        harmonyMode: harmonyMode,
        isDarkMode: isDarkMode,
        radiusScale: radiusScale,
      ),
    );
  }
}

/// Converts a Flutter [Color] to a [CoreColor].
CoreColor _toCoreColor(Color color) => .new(color.toARGB32());

/// Converts a Flutter [Color] to a [CoreColor] for an icon colour slot.
CoreColor _iconColor(Color color) => .new(color.toARGB32());

ThemeData _generateCustomTheme({
  required double primaryHue,
  required ColorHarmony harmonyMode,
  required bool isDarkMode,
  required double radiusScale,
}) {
  final baseLightness = isDarkMode
      ? _ThemeConstants.darkModeBaseLightness
      : _ThemeConstants.lightModeBaseLightness;
  final baseChroma = isDarkMode
      ? _ThemeConstants.darkModeBaseChroma
      : _ThemeConstants.lightModeBaseChroma;

  final (secondaryHue, accentHue) = _calculateHarmonyHues(
    primaryHue: primaryHue,
    harmonyMode: harmonyMode,
  );

  final primary = CoreColorConversion.oklchToColor(
    baseLightness,
    baseChroma,
    primaryHue,
  ).toValue();
  final secondaryColor = CoreColorConversion.oklchToColor(
    baseLightness,
    baseChroma * _ThemeConstants.secondaryChromaRatio,
    secondaryHue,
  ).toValue();
  final accent = CoreColorConversion.oklchToColor(
    baseLightness,
    baseChroma * _ThemeConstants.accentChromaRatio,
    accentHue,
  ).toValue();

  final hue = primaryHue % _ThemeConstants.maxHue;
  final base100 = _generateBaseColor(
    isDarkMode
        ? _ThemeConstants.darkBase100Lightness
        : _ThemeConstants.lightBase100Lightness,
    hue,
    isDarkMode,
  );
  final base200 = _generateBaseColor(
    isDarkMode
        ? _ThemeConstants.darkBase200Lightness
        : _ThemeConstants.lightBase200Lightness,
    hue,
    isDarkMode,
  );
  final base300 = _generateBaseColor(
    isDarkMode
        ? _ThemeConstants.darkBase300Lightness
        : _ThemeConstants.lightBase300Lightness,
    hue,
    isDarkMode,
  );
  final baseContent = _generateBaseColor(
    isDarkMode
        ? _ThemeConstants.darkBaseContentLightness
        : _ThemeConstants.lightBaseContentLightness,
    hue,
    isDarkMode,
  );
  final neutral = _generateBaseColor(
    isDarkMode
        ? _ThemeConstants.darkNeutralLightness
        : _ThemeConstants.lightNeutralLightness,
    hue,
    isDarkMode,
  );

  final primaryContent = _getContrastColor(primary);
  final secondaryContent = _getContrastColor(secondaryColor);
  final accentContent = _getContrastColor(accent);

  final darkContentCore = _toCoreColor(_SemanticContentColors.darkContent);

  return ThemeData(
    // Semantic colors intentionally share content colors
    // (dark for most, light for error).
    colorScheme:
        ColorScheme(
          primary: _toCoreColor(primary),
          secondary: _toCoreColor(secondaryColor),
          error: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(60% 0.22 25)').toValue(),
          ),
          success: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(65% 0.17 145)').toValue(),
          ),
          warning: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(80% 0.18 85)').toValue(),
          ),
          info: _toCoreColor(
            CoreColorConversion.fromOKLch('oklch(70% 0.15 230)').toValue(),
          ),
          surface: _toCoreColor(base100),
          surfaceContainer: _toCoreColor(base200),
          surfaceContainerHigh: _toCoreColor(base300),
          onSurface: _toCoreColor(baseContent),
          onPrimary: _toCoreColor(primaryContent),
          onSecondary: _toCoreColor(secondaryContent),
          tertiary: _toCoreColor(accent),
          onTertiary: _toCoreColor(accentContent),
          onError: _toCoreColor(_SemanticContentColors.lightContent),
          onSuccess: darkContentCore,
          onWarning: darkContentCore,
          onInfo: darkContentCore,
          outline: _toCoreColor(neutral),
        ).resolved(
          isDarkMode ? .dark : .light,
        ),
    radiusScaling: radiusScale / _DemoData.defaultRadius,
  );
}

(double, double) _calculateHarmonyHues({
  required double primaryHue,
  required ColorHarmony harmonyMode,
}) {
  const maxHue = _ThemeConstants.maxHue;

  return switch (harmonyMode) {
    .complementary => (
      (primaryHue + _ThemeConstants.complementaryHueOffset) % maxHue,
      (primaryHue + _ThemeConstants.analogousHueOffset) % maxHue,
    ),
    .analogous => (
      (primaryHue + _ThemeConstants.analogousHueOffset) % maxHue,
      (primaryHue - _ThemeConstants.analogousHueOffset + maxHue) % maxHue,
    ),
    .monochromatic => (primaryHue, primaryHue),
    .triadic => (
      (primaryHue + _ThemeConstants.triadicHueOffset) % maxHue,
      (primaryHue + _ThemeConstants.triadicHueOffset * 2) % maxHue,
    ),
  };
}

Color _generateBaseColor(int lightness, double hue, bool isDarkMode) {
  final chroma = isDarkMode
      ? _ChromaValues.darkMode
      : lightness > _ChromaValues.lightnessThreshold
      ? _ChromaValues.lightModeHigh
      : _ChromaValues.lightModeLow;

  return CoreColorConversion.fromOKLch(
    'oklch($lightness% $chroma $hue)',
  ).toValue();
}

Color _getContrastColor(Color color) {
  final luminance = color.computeLuminance();

  return luminance > _DemoData.luminanceThreshold
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);
}

// =============================================================================
// STORIES
// =============================================================================

/// Interactive host for the component demo gallery.
///
/// When [useCustomTheme] is enabled, the gallery is wrapped in a theme
/// generated from [primaryHue], [harmonyMode], [darkMode] and [radiusScale].
class ComponentDemo extends StatelessWidget {
  /// Creates a [ComponentDemo].
  const ComponentDemo({
    super.key,
    this.useCustomTheme = false,
    this.primaryHue = _DemoData.initialHue,
    this.harmonyMode = ColorHarmony.triadic,
    this.darkMode = false,
    this.radiusScale = _DemoData.defaultRadius,
  });

  /// Whether to wrap the gallery in a generated custom theme.
  final bool useCustomTheme;

  /// Primary color hue in degrees (0-360) for the generated theme.
  final double primaryHue;

  /// Color harmony mode deriving secondary and accent hues.
  final ColorHarmony harmonyMode;

  /// Whether the generated theme uses dark brightness.
  final bool darkMode;

  /// Border radius scale in logical pixels for the generated theme.
  final double radiusScale;

  @override
  Widget build(BuildContext context) {
    if (!useCustomTheme) {
      return const _ComponentDemoPage();
    }

    final customTheme = _ThemeCache.getOrGenerate(
      primaryHue: primaryHue,
      harmonyMode: harmonyMode,
      isDarkMode: darkMode,
      radiusScale: radiusScale,
    );

    return Theme(
      data: applyPreviewSurface(context, customTheme),
      child: const _ComponentDemoPage(),
    );
  }
}

/// Navigation metadata for the Component Demo foundation page.
const kComponentMeta = ComponentMeta(
  name: 'Component Demo',
  path: 'foundation',
);

/// Story metadata for [ComponentDemo].
const kMeta = Meta(ComponentDemo.new);

/// Component demo gallery using the ambient app theme.
final $Default = _Story();

/// Gallery wrapped in a generated custom theme.
final $CustomTheme = _Story(
  name: 'Custom Theme',
  args: _Args(useCustomTheme: BoolArg(true)),
);

// =============================================================================
// MAIN PAGE
// =============================================================================

class _ComponentDemoPage extends StatelessWidget {
  const _ComponentDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return ColoredBox(
      color: colorScheme.surface.toValue(),
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('component_demo_scroll'),
        padding: const .all(24),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(tp.component_demos).headlineLarge(),
            const SizedBox(height: _Size.s8),
            Text(
              tp.component_demos_desc,
            ).onSurface(),
            const SizedBox(height: _Size.s24),
            const _ComponentsDemoGrid(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MASONRY GRID
// =============================================================================

class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount =
            ((constraints.maxWidth + _DemoConstants.cardSpacing) /
                    (_DemoConstants.minCardWidth + _DemoConstants.cardSpacing))
                .floor()
                .clamp(
                  _DemoData.mobileColumnCount,
                  _DemoData.desktopColumnCount,
                );

        final columns = List.generate(
          columnCount,
          (columnIndex) => <Widget>[
            for (final (i, child) in children.indexed)
              if (i % columnCount == columnIndex) child,
          ],
        );

        return Row(
          crossAxisAlignment: .start,
          children: [
            for (final (columnIndex, columnWidgets) in columns.indexed) ...[
              if (columnIndex > 0)
                const SizedBox(width: _DemoConstants.cardSpacing),
              Expanded(
                child: Column(
                  spacing: _DemoConstants.cardSpacing,
                  children: columnWidgets,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// =============================================================================
// DEMO CARD
// =============================================================================

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const .all(_DemoConstants.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface.toValue(),
        border: .all(
          color: theme.colorScheme.surfaceContainerHigh.withValues(
            alpha: _Opacity.half,
          ),
        ),
        borderRadius: .circular(_DemoConstants.cardRadius),
      ),
      child: child,
    );
  }
}

// =============================================================================
// COMPONENTS DEMO GRID
// =============================================================================

class _ComponentsDemoGrid extends StatelessWidget {
  const _ComponentsDemoGrid();

  @override
  Widget build(BuildContext context) {
    return const _MasonryGrid(
      children: [
        _FilterDemoCard(),
        _StatsDemoCard(),
        _MediaPlayerDemoCard(),
        _CalendarDemoCard(),
        _OrdersListDemoCard(),
        _TerminalDemoCard(),
        _ScoreDemoCard(),
        _AlertStackDemoCard(),
        _SliderDemoCard(),
        _ProductDemoCard(),
        _SearchDemoCard(),
        _RegisterFormDemoCard(),
        _RevenueDemoCard(),
        _PostEditorDemoCard(),
        _ChatDemoCard(),
        _PricingDemoCard(),
        _AdminMenuDemoCard(),
        _TodoListDemoCard(),
        _PaymentMethodDemoCard(),
        _TeamInviteDemoCard(),
        _StatusTabsDemoCard(),
        _ChatInputDemoCard(),
        _PriceRangeDemoCard(),
        _UrlInputDemoCard(),
        _AiSearchDemoCard(),
        _TwoFactorAuthDemoCard(),
        _ProfileVerifiedDemoCard(),
        _ComputeEnvironmentDemoCard(),
        _NumberStepperDemoCard(),
        _ToggleSettingDemoCard(),
        _EmailActionsDemoCard(),
        _PaginationDemoCard(),
        _SurveyDemoCard(),
        _ProcessingDemoCard(),
        _StorageUsageDemoCard(),
        _UsernameInputDemoCard(),
        _TermsCheckboxDemoCard(),
        _AddContextDemoCard(),
        _SearchResultsDemoCard(),
        _BillingAddressDemoCard(),
      ],
    );
  }
}

// =============================================================================
// DEMO CARDS
// =============================================================================

class _FilterDemoCard extends StatelessWidget {
  const _FilterDemoCard();

  static Widget _buildFilterItem(
    BuildContext context,
    String label,
    int count,
    bool checked, [
    Color? badgeColor,
  ]) {
    final theme = Theme.of(context);

    return Padding(
      padding: const .symmetric(vertical: _Size.s4),
      child: Row(
        children: [
          Checkbox(
            onChanged: (_) {},
            checked: checked,
          ),
          const SizedBox(width: _Size.s8),
          Expanded(child: Text(label)),
          Container(
            padding: const .symmetric(vertical: _Size.s2, horizontal: _Size.s8),
            decoration: BoxDecoration(
              color: badgeColor ?? theme.colorScheme.primary.toValue(),
              borderRadius: .circular(_Size.s12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: material.Colors.white,
                fontSize: _Size.s12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Row(
                spacing: _Size.s8,
                children: [
                  const Icon(
                    LucideIcons.eye,
                    iconStyle: CoreIconStyle(size: _Size.s16),
                  ),
                  Text(tp.preview).semiBold(),
                ],
              ),
              Text(tp.more).bodySmall().onSurface(),
            ],
          ),
          const SizedBox(height: _Size.s12),
          Wrap(
            spacing: _Size.s8,
            children: [
              Chip(
                child: Row(
                  mainAxisSize: .min,
                  spacing: _Size.s4,
                  children: [
                    Text(tp.shoes),
                    const Icon(
                      LucideIcons.x,
                      iconStyle: CoreIconStyle(size: _Size.s12),
                    ),
                  ],
                ),
              ),
              Chip(
                child: Row(
                  mainAxisSize: .min,
                  spacing: _Size.s4,
                  children: [
                    Text(tp.bags),
                    const Icon(
                      LucideIcons.x,
                      iconStyle: CoreIconStyle(size: _Size.s12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: _Size.s16),
          _buildFilterItem(
            context,
            tp.hoodies,
            _FilterCounts.hoodies,
            true,
          ),
          _buildFilterItem(
            context,
            tp.bags,
            _FilterCounts.bags,
            true,
          ),
          _buildFilterItem(
            context,
            tp.shoes,
            _FilterCounts.shoes,
            false,
            colorScheme.error.toValue(),
          ),
          _buildFilterItem(
            context,
            tp.accessories,
            _FilterCounts.accessories,
            false,
          ),
        ],
      ),
    );
  }
}

class _StatsDemoCard extends StatelessWidget {
  const _StatsDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            height: _Size.s60,
            child: Row(
              crossAxisAlignment: .end,
              children: [
                for (int i = 0; i < _ChartHeights.barCount; i += 1)
                  Expanded(
                    child: Padding(
                      padding: const .symmetric(horizontal: _Size.s2),
                      child: FractionallySizedBox(
                        heightFactor: _ChartHeights.values[i],
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh.toValue(),
                            borderRadius: .circular(_Size.s2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: _Size.s16),
          Text(
            tp.sales_volume_text,
          ).bodySmall(),
          const SizedBox(height: _Size.s16),
          Row(
            spacing: _Size.s8,
            children: [
              Expanded(
                child: Button(
                  onPressed: () {},
                  variant: .outline,
                  child: Text(tp.charts),
                ),
              ),
              Expanded(
                child: Button(
                  onPressed: () {},
                  child: Text(tp.details),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaPlayerDemoCard extends StatelessWidget {
  const _MediaPlayerDemoCard();

  static Widget _buildControlIcon(BuildContext context, IconName icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const .all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.toValue(),
        shape: .circle,
      ),
      child: Icon(
        icon,
        iconStyle: const CoreIconStyle(size: _Size.s20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: .center,
            spacing: _Size.s8,
            children: [
              _buildControlIcon(context, LucideIcons.skipBack),
              Container(
                padding: const .all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.toValue(),
                  shape: .circle,
                ),
                child: const Icon(
                  LucideIcons.play,
                  iconStyle: CoreIconStyle(size: _Size.s24),
                ),
              ),
              _buildControlIcon(context, LucideIcons.skipForward),
            ],
          ),
          const SizedBox(height: _Size.s16),
          Text(tp.pm_zoomcall).semiBold(),
          Text(tp.pm_talking).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          const Progress(value: 0.45),
          const SizedBox(height: _Size.s8),
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              const Text('13:39').bodySmall().onSurface(),
              const Text('120:00').bodySmall().onSurface(),
            ],
          ),
          const SizedBox(height: _Size.s12),
          const Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              Icon(
                LucideIcons.volume2,
                iconStyle: CoreIconStyle(size: _Size.s20),
              ),
              Icon(
                LucideIcons.shuffle,
                iconStyle: CoreIconStyle(size: _Size.s20),
              ),
              Icon(
                LucideIcons.repeat,
                iconStyle: CoreIconStyle(size: _Size.s20),
              ),
              Icon(
                LucideIcons.headphones,
                iconStyle: CoreIconStyle(size: _Size.s20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDemoCard extends StatelessWidget {
  const _CalendarDemoCard();

  static Widget _buildDayCell(
    BuildContext context,
    String text,
    bool selected,
  ) {
    final theme = Theme.of(context);
    final parts = text.split('\n');

    return Container(
      padding: const .all(8),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.toValue()
            : material.Colors.transparent,
        borderRadius: .circular(_Size.s8),
      ),
      child: Column(
        children: [
          Text(
            parts.first,
            style: TextStyle(
              color: selected ? material.Colors.white : null,
              fontSize: _Size.s12,
            ),
          ),
          Text(
            parts[1],
            style: TextStyle(
              color: selected ? material.Colors.white : null,
              fontSize: _Size.s12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceContainerColor = colorScheme.surfaceContainer.toValue();
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            mainAxisAlignment: .spaceAround,
            children: [
              for (final day in [
                '12\nM',
                '13\nT',
                '14\nW',
                '15\nT',
                '16\nF',
                '17\nS',
                '18\nS',
              ])
                _buildDayCell(context, day, day.startsWith('14')),
            ],
          ),
          const SizedBox(height: _Size.s16),
          // Demo TextField - no state management needed.
          TextField(
            placeholder: Text(
              tp.search_for_events,
            ),
            prefix: const Icon(
              LucideIcons.search,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
          const SizedBox(height: _Size.s12),
          Row(
            spacing: _Size.s8,
            children: [
              Toggle(onChanged: (_) {}, value: true),
              Text(tp.show_all_day_events),
            ],
          ),
          const SizedBox(height: _Size.s16),
          Container(
            padding: const .all(12),
            decoration: BoxDecoration(
              color: surfaceContainerColor,
              borderRadius: .circular(_Size.s8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        tp.team_sync_meeting,
                      ).semiBold(),
                      Text(
                        tp.weekly_product_review,
                      ).bodySmall().onSurface(),
                    ],
                  ),
                ),
                Badge(
                  child: Text(tp.one_hour),
                ),
              ],
            ),
          ),
          const SizedBox(height: _Size.s16),
          Row(
            children: [
              for (final tab in [
                tp.tab_1,
                tp.tab_2,
                tp.tab_3,
              ])
                Padding(
                  padding: const .only(right: 16),
                  child: Text(tab).onSurface(),
                ),
            ],
          ),
          const SizedBox(height: _Size.s8),
          Container(
            padding: const .all(12),
            decoration: BoxDecoration(
              color: surfaceContainerColor,
              borderRadius: .circular(_Size.s8),
            ),
            child: Text(tp.tab_content_2),
          ),
        ],
      ),
    );
  }
}

class _OrdersListDemoCard extends StatelessWidget {
  const _OrdersListDemoCard();

  static Widget _buildOrderItem(
    BuildContext context,
    String name,
    String status,
    String type,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = switch (type) {
      'error' => colorScheme.error.toValue(),
      'warning' => colorScheme.warning.toValue(),
      'success' => colorScheme.success.toValue(),
      _ => colorScheme.info.toValue(),
    };

    return Padding(
      padding: const .symmetric(vertical: _Size.s6),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(name),
          Container(
            padding: const .symmetric(vertical: _Size.s2, horizontal: _Size.s8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: .circular(_Size.s12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: material.Colors.white,
                fontSize: _Size.s12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            spacing: _Size.s8,
            children: [
              const Icon(
                LucideIcons.list,
                iconStyle: CoreIconStyle(size: _Size.s16),
              ),
              Text(tp.recent_orders).semiBold(),
            ],
          ),
          const SizedBox(height: _Size.s16),
          _buildOrderItem(
            context,
            tp.name_charlie,
            tp.send,
            'info',
          ),
          _buildOrderItem(
            context,
            tp.name_howard,
            tp.failed,
            'error',
          ),
          _buildOrderItem(
            context,
            tp.name_fiona,
            tp.in_progress,
            'warning',
          ),
          _buildOrderItem(
            context,
            tp.name_nick,
            tp.completed,
            'success',
          ),
          _buildOrderItem(
            context,
            tp.name_amanda,
            tp.completed,
            'success',
          ),
        ],
      ),
    );
  }
}

class _TerminalDemoCard extends StatelessWidget {
  const _TerminalDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const Row(
            spacing: _Size.s8,
            children: [
              SizedBox.square(
                dimension: _Size.s12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFFF5F56),
                    shape: .circle,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: _Size.s12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFBD2E),
                    shape: .circle,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: _Size.s12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF27C93F),
                    shape: .circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _Size.s16),
          Text(
            tp.install_command,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'monospace',
            ),
          ),
          Text(
            tp.installing,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontFamily: 'monospace',
            ),
          ),
          Text(
            tp.done,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreDemoCard extends StatelessWidget {
  const _ScoreDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: _Size.s4,
              children: [
                Text(
                  tp.page_score,
                ).bodySmall().onSurface(),
                Row(
                  crossAxisAlignment: .end,
                  children: [
                    const Text('91').displaySmall(),
                    const Text('/100').onSurface(),
                  ],
                ),
                Row(
                  spacing: _Size.s4,
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      iconStyle: CoreIconStyle(
                        size: _Size.s16,
                        color: _iconColor(colorScheme.success.toValue()),
                      ),
                    ),
                    Text(tp.all_good).bodySmall(),
                  ],
                ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: _Size.s60,
            child: Stacks(
              alignment: .center,
              children: [
                const RadialProgress(
                  value: 0.91,
                ),
                const Text('91').semiBold(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertStackDemoCard extends StatelessWidget {
  const _AlertStackDemoCard();

  static Widget _buildAlert(
    BuildContext context,
    IconName icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _Opacity.subtle),
        borderRadius: .circular(_Size.s8),
      ),
      child: Row(
        spacing: _Size.s12,
        children: [
          Icon(
            icon,
            iconStyle: CoreIconStyle(
              size: _Size.s20,
              color: CoreColor(color.toARGB32()),
            ),
          ),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  static Widget _buildAlertWithAction(
    BuildContext context,
    IconName icon,
    String text,
    String action,
    Color color,
  ) {
    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _Opacity.subtle),
        borderRadius: .circular(_Size.s8),
      ),
      child: Row(
        spacing: _Size.s12,
        children: [
          Icon(
            icon,
            iconStyle: CoreIconStyle(
              size: _Size.s20,
              color: CoreColor(color.toARGB32()),
            ),
          ),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
          Text(action, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        spacing: _Size.s8,
        children: [
          _buildAlert(
            context,
            LucideIcons.mail,
            tp.new_messages(count: _DemoValues.newMessageCount),
            colorScheme.info.toValue(),
          ),
          _buildAlert(
            context,
            LucideIcons.circleCheck,
            tp.verification_completed,
            colorScheme.success.toValue(),
          ),
          _buildAlert(
            context,
            LucideIcons.clock,
            tp.click_to_verify,
            colorScheme.warning.toValue(),
          ),
          _buildAlertWithAction(
            context,
            LucideIcons.lock,
            tp.access_denied,
            tp.support,
            colorScheme.error.toValue(),
          ),
        ],
      ),
    );
  }
}

class _SliderDemoCard extends StatelessWidget {
  const _SliderDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            spacing: _Size.s8,
            children: [
              const Icon(
                LucideIcons.slidersHorizontal,
                iconStyle: CoreIconStyle(size: _Size.s16),
              ),
              Text(tp.price_range),
            ],
          ),
          const SizedBox(height: _Size.s24),
          Center(
            child: Text(tp.slider_value).displaySmall(),
          ),
          const SizedBox(height: _Size.s16),
          Slider(
            onChanged: (_) {},
            value: _DemoValues.sliderValue,
          ),
        ],
      ),
    );
  }
}

class _ProductDemoCard extends StatelessWidget {
  const _ProductDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Stacks(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.toValue(),
                  borderRadius: .circular(_Size.s8),
                ),
                height: _Size.s120,
                child: Center(
                  child: Icon(
                    LucideIcons.image,
                    iconStyle: CoreIconStyle(
                      size: _Size.s48,
                      color: _iconColor(
                        colorScheme.surfaceContainerHigh.toValue(),
                      ),
                    ),
                  ),
                ),
              ),
              // Intentional equal offset for corner positioning.
              Position(
                top: _Size.s8,
                right: _Size.s8,
                child: Badge(
                  child: Text(tp.sale),
                ),
              ),
            ],
          ),
          const SizedBox(height: _Size.s12),
          Text(tp.nike_shoes).semiBold(),
          const SizedBox(height: _Size.s4),
          Row(
            spacing: _Size.s8,
            children: [
              Text(tp.star_rating).bodySmall(),
              Text(
                tp.n_reviews(count: _DemoValues.reviewCount),
              ).bodySmall().onSurface(),
            ],
          ),
          const SizedBox(height: _Size.s8),
          Row(
            spacing: _Size.s8,
            children: [
              Text(
                tp.price_amount(amount: _DemoValues.priceSmall),
              ).semiBold(),
              Text(
                tp.price_amount(amount: _DemoValues.priceMedium),
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(
                    alpha: _Opacity.half,
                  ),
                  decoration: .lineThrough,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchDemoCard extends StatelessWidget {
  const _SearchDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Row(
        spacing: _Size.s8,
        children: [
          Expanded(
            // Demo TextField - no state management needed.
            child: TextField(
              placeholder: Text(tp.search),
              prefix: const Icon(
                LucideIcons.search,
                iconStyle: CoreIconStyle(size: _Size.s16),
              ),
            ),
          ),
          Button(
            onPressed: () {},
            child: Text(tp.find),
          ),
        ],
      ),
    );
  }
}

class _RegisterFormDemoCard extends StatelessWidget {
  const _RegisterFormDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            spacing: _Size.s8,
            children: [
              const Icon(
                LucideIcons.userPlus,
                iconStyle: CoreIconStyle(size: _Size.s20),
              ),
              Text(tp.create_account).semiBold(),
            ],
          ),
          const SizedBox(height: _Size.s8),
          Text(
            tp.create_account_desc,
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          // Demo TextField - no state management needed.
          TextField(
            placeholder: Text(tp.username),
            prefix: const Icon(
              LucideIcons.user,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
          const SizedBox(height: _Size.s12),
          // Demo TextField - no state management needed.
          TextField(
            placeholder: Text(tp.password),
            obscureText: true,
            prefix: const Icon(
              LucideIcons.lock,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
          const SizedBox(height: _Size.s4),
          Row(
            spacing: _Size.s8,
            children: [
              SizedBox.square(
                dimension: _Size.s8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.error.toValue(),
                    shape: .circle,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  tp.password_weak,
                ).bodySmall().onSurface(),
              ),
            ],
          ),
          const SizedBox(height: _Size.s12),
          Row(
            spacing: _Size.s8,
            children: [
              Checkbox(
                onChanged: (_) {},
                checked: false,
              ),
              Flexible(
                child: Text(
                  tp.accept_terms_without_reading,
                ).bodySmall(),
              ),
            ],
          ),
          const SizedBox(height: _Size.s8),
          Row(
            spacing: _Size.s8,
            children: [
              Toggle(onChanged: (_) {}, value: true),
              Flexible(
                child: Text(
                  tp.subscribe_spam,
                ).bodySmall(),
              ),
            ],
          ),
          const SizedBox(height: _Size.s16),
          Row(
            spacing: _Size.s12,
            children: [
              Button(
                onPressed: () {},
                child: Text(tp.register),
              ),
              Text(tp.or_login).onSurface(),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueDemoCard extends StatelessWidget {
  const _RevenueDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        spacing: _Size.s4,
        children: [
          Text(
            tp.december_revenue,
          ).bodySmall().onSurface(),
          Text(tp.revenue_amount).headlineLarge(),
          Row(
            spacing: _Size.s4,
            children: [
              Icon(
                LucideIcons.trendingUp,
                iconStyle: CoreIconStyle(
                  size: _Size.s16,
                  color: _iconColor(colorScheme.success.toValue()),
                ),
              ),
              Flexible(
                child: Text(
                  tp.revenue_trend,
                ).bodySmall(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostEditorDemoCard extends StatelessWidget {
  const _PostEditorDemoCard();

  static Widget _buildFormatButton(
    BuildContext context,
    String label,
    bool bold,
  ) {
    // Intentional square button (equal width/height).
    return Container(
      alignment: .center,
      decoration: BoxDecoration(
        border: .all(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHigh.toValue(),
        ),
        borderRadius: .circular(_Size.s4),
      ),
      width: _Size.s32,
      height: _Size.s32,
      margin: const .only(right: 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: bold ? .bold : .normal,
          fontStyle: label == 'I' ? .italic : .normal,
          decoration: label == 'U' ? .underline : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            spacing: _Size.s8,
            children: [
              const Icon(
                LucideIcons.pencil,
                iconStyle: CoreIconStyle(size: _Size.s16),
              ),
              Text(tp.write_post),
            ],
          ),
          const SizedBox(height: _Size.s16),
          Row(
            children: [
              _buildFormatButton(context, 'B', true),
              _buildFormatButton(context, 'I', false),
              _buildFormatButton(context, 'U', false),
              const Spacer(),
              Button(
                onPressed: () {},
                size: .sm,
                child: Text(tp.add_files),
              ),
            ],
          ),
          const SizedBox(height: _Size.s12),
          Container(
            padding: const .all(12),
            decoration: BoxDecoration(
              border: .all(
                color: colorScheme.surfaceContainerHigh.toValue(),
              ),
              borderRadius: .circular(_Size.s8),
            ),
            height: _Size.s80,
            child: Align(
              alignment: .topLeft,
              child: Text(tp.post_placeholder),
            ),
          ),
          const SizedBox(height: _Size.s8),
          Text(
            tp.characters_remaining(count: _DemoValues.maxCharacters),
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          Row(
            spacing: _Size.s8,
            children: [
              Expanded(
                child: Button(
                  onPressed: () {},
                  variant: .outline,
                  child: Text(tp.draft),
                ),
              ),
              Expanded(
                child: Button(
                  onPressed: () {},
                  child: Text(tp.publish),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatDemoCard extends StatelessWidget {
  const _ChatDemoCard();

  static Widget _buildMessage(
    BuildContext context,
    String sender,
    String text,
    bool isOther,
    String? time, [
    String? status,
  ]) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: isOther ? .start : .end,
      children: [
        if (time != null)
          Padding(
            padding: const .only(bottom: 4),
            child: Text('$sender $time').bodySmall().onSurface(),
          ),
        Row(
          mainAxisAlignment: isOther ? .start : .end,
          children: [
            if (isOther)
              Padding(
                padding: const .only(right: 8),
                child: Avatar(
                  initials: sender[0],
                  size: .sm,
                ),
              ),
            Container(
              padding: const .symmetric(
                vertical: _Size.s8,
                horizontal: _Size.s12,
              ),
              decoration: BoxDecoration(
                color: isOther
                    ? colorScheme.surfaceContainer.toValue()
                    : colorScheme.primary.toValue(),
                borderRadius: .circular(_Size.s16),
              ),
              child: Text(
                text,
                style: TextStyle(color: isOther ? null : material.Colors.white),
              ),
            ),
            if (!isOther)
              const Padding(
                padding: .only(left: 8),
                child: Avatar(
                  initials: 'Y',
                  size: .sm,
                ),
              ),
          ],
        ),
        if (status != null)
          Padding(
            padding: const .only(top: 4),
            child: Text(status).bodySmall().onSurface(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        children: [
          _buildMessage(
            context,
            tp.kenobi,
            tp.high_ground,
            true,
            '12:45',
          ),
          const SizedBox(height: _Size.s8),
          _buildMessage(
            context,
            tp.anakin,
            tp.underestimate_power,
            true,
            null,
            tp.delivered,
          ),
          const SizedBox(height: _Size.s8),
          _buildMessage(
            context,
            tp.you,
            tp.underestimate_power,
            false,
            tp.hello_message,
          ),
          const SizedBox(height: _Size.s16),
          const Divider(),
          const SizedBox(height: _Size.s12),
          const Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              Icon(
                LucideIcons.phone,
                iconStyle: CoreIconStyle(size: _Size.s24),
              ),
              Icon(
                LucideIcons.messageCircle,
                iconStyle: CoreIconStyle(size: _Size.s24),
              ),
              Icon(
                LucideIcons.settings,
                iconStyle: CoreIconStyle(size: _Size.s24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingDemoCard extends StatelessWidget {
  const _PricingDemoCard();

  static Widget _buildFeature(
    BuildContext context,
    String text,
    bool included,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const .symmetric(vertical: _Size.s4),
      child: Row(
        spacing: _Size.s8,
        children: [
          Icon(
            included ? LucideIcons.circleCheck : LucideIcons.circleX,
            iconStyle: CoreIconStyle(
              size: _Size.s16,
              color: _iconColor(
                included
                    ? colorScheme.success.toValue()
                    : colorScheme.error.toValue(),
              ),
            ),
          ),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: .center,
            spacing: _Size.s8,
            children: [
              Container(
                padding: const .symmetric(
                  vertical: _Size.s8,
                  horizontal: _Size.s16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.toValue(),
                  borderRadius: .circular(_Size.s20),
                ),
                child: Text(tp.monthly),
              ),
              Stacks(
                clipBehavior: .none,
                children: [
                  Container(
                    padding: const .symmetric(
                      vertical: _Size.s8,
                      horizontal: _Size.s16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.toValue(),
                      borderRadius: .circular(_Size.s20),
                    ),
                    child: Text(
                      tp.yearly,
                      style: const TextStyle(color: material.Colors.white),
                    ),
                  ),
                  Position(
                    top: -_Size.s8,
                    right: -_Size.s8,
                    child: Badge(
                      child: Text(tp.sale),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: _Size.s24),
          Text(tp.starter_plan).bodySmall().onSurface(),
          Row(
            mainAxisAlignment: .center,
            crossAxisAlignment: .end,
            children: [
              Text(
                tp.price_amount(amount: _DemoValues.priceLarge),
              ).displaySmall(),
              Text(tp.per_month).onSurface(),
            ],
          ),
          const SizedBox(height: _Size.s16),
          _buildFeature(
            context,
            tp.unlimited_projects,
            true,
          ),
          _buildFeature(
            context,
            tp.priority_support,
            true,
          ),
          _buildFeature(context, tp.analytics, true),
          _buildFeature(context, tp.api_access, false),
          const SizedBox(height: _Size.s16),
          SizedBox(
            width: .infinity,
            child: Button(
              onPressed: () {},
              child: Text(tp.buy_now),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuDemoCard extends StatelessWidget {
  const _AdminMenuDemoCard();

  static Widget _buildMenuItem(
    BuildContext context,
    IconName icon,
    String label, {
    String? badge,
    bool hasDot = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const .symmetric(vertical: _Size.s8),
      child: Row(
        children: [
          Icon(icon, iconStyle: const CoreIconStyle(size: _Size.s20)),
          const SizedBox(width: _Size.s12),
          Expanded(child: Text(label)),
          if (badge != null)
            Badge(
              variant: CoreBadgeVariant.filled,
              form: CoreBadgeForm.count,
              size: CoreComponentSize.xs,
              child: Text(badge),
            ),
          if (hasDot)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.info.toValue(),
                shape: .circle,
              ),
              width: _Size.s8,
              height: _Size.s8,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(tp.admin_panel).bodySmall().onSurface(),
          const SizedBox(height: _Size.s12),
          _buildMenuItem(
            context,
            LucideIcons.database,
            tp.databases,
            badge: '7',
          ),
          _buildMenuItem(
            context,
            LucideIcons.package,
            tp.products,
          ),
          _buildMenuItem(
            context,
            LucideIcons.mail,
            tp.messages,
            badge: '29',
          ),
          _buildMenuItem(
            context,
            LucideIcons.keyRound,
            tp.access_tokens,
          ),
          _buildMenuItem(
            context,
            LucideIcons.users,
            tp.users,
            hasDot: true,
          ),
          _buildMenuItem(
            context,
            LucideIcons.chartColumn,
            tp.settings,
          ),
        ],
      ),
    );
  }
}

class _TodoListDemoCard extends StatelessWidget {
  const _TodoListDemoCard();

  static Widget _buildTodoItem(
    BuildContext context,
    String text,
    bool checked,
  ) {
    return Padding(
      padding: const .symmetric(vertical: _Size.s4),
      child: Row(
        spacing: _Size.s8,
        children: [
          Checkbox(
            onChanged: (_) {},
            checked: checked,
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                decoration: checked ? .lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        children: [
          _buildTodoItem(
            context,
            tp.hp_sorcerers_stack,
            true,
          ),
          _buildTodoItem(
            context,
            tp.hp_chamber_of_servers,
            true,
          ),
          _buildTodoItem(
            context,
            tp.hp_prisoner_of_azure,
            true,
          ),
          _buildTodoItem(
            context,
            tp.hp_goblet_of_firebase,
            true,
          ),
          _buildTodoItem(
            context,
            tp.hp_elixir_of_phoenix,
            true,
          ),
          _buildTodoItem(
            context,
            tp.hp_half_deployed_app,
            false,
          ),
          _buildTodoItem(
            context,
            tp.hp_deathly_frameworks,
            false,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodDemoCard extends StatelessWidget {
  const _PaymentMethodDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceContainerHighColor = colorScheme.surfaceContainerHigh
        .toValue();
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(tp.payment_method).semiBold(),
          const SizedBox(height: _Size.s4),
          Text(
            tp.all_transactions_secure,
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          Text(tp.name_on_card).bodySmall(),
          const SizedBox(height: _Size.s4),
          // Demo TextField - no state management needed.
          TextField(
            placeholder: Text(tp.john_doe),
          ),
          const SizedBox(height: _Size.s12),
          Row(
            spacing: _Size.s12,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: _Size.s4,
                  children: [
                    Text(tp.card_number).bodySmall(),
                    // Demo TextField - no state management needed.
                    TextField(
                      placeholder: Text(
                        tp.card_number_placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: _Size.s4,
                  children: [
                    Text(tp.cvv).bodySmall(),
                    // Demo TextField - no state management needed.
                    TextField(
                      placeholder: Text(
                        tp.cvv_placeholder,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: _Size.s4),
          Text(
            tp.card_number_desc,
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s12),
          Row(
            spacing: _Size.s12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: _Size.s4,
                  children: [
                    Text(tp.month).bodySmall(),
                    Container(
                      padding: const .symmetric(
                        vertical: _Size.s10,
                        horizontal: _Size.s12,
                      ),
                      decoration: BoxDecoration(
                        border: .all(color: surfaceContainerHighColor),
                        borderRadius: .circular(_Size.s8),
                      ),
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text(
                            tp.month_placeholder,
                          ).onSurface(),
                          const Icon(
                            LucideIcons.chevronDown,
                            iconStyle: CoreIconStyle(size: _Size.s16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: _Size.s4,
                  children: [
                    Text(tp.year).bodySmall(),
                    Container(
                      padding: const .symmetric(
                        vertical: _Size.s10,
                        horizontal: _Size.s12,
                      ),
                      decoration: BoxDecoration(
                        border: .all(color: surfaceContainerHighColor),
                        borderRadius: .circular(_Size.s8),
                      ),
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text(
                            tp.year_placeholder,
                          ).onSurface(),
                          const Icon(
                            LucideIcons.chevronDown,
                            iconStyle: CoreIconStyle(size: _Size.s16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamInviteDemoCard extends StatelessWidget {
  const _TeamInviteDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: .center,
            children: [
              const Avatar(initials: 'JD'),
              Transform.translate(
                offset: const Offset(-8, 0),
                child: const Avatar(initials: 'AB'),
              ),
              Transform.translate(
                offset: const Offset(-16, 0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: material.Colors.blue,
                    shape: .circle,
                  ),
                  width: _Size.s40,
                  height: _Size.s40,
                  child: const Icon(
                    LucideIcons.check,
                    iconStyle: CoreIconStyle(
                      size: _Size.s20,
                      color: CoreColor(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _Size.s16),
          Text(tp.no_team_members).semiBold(),
          const SizedBox(height: _Size.s4),
          Text(
            tp.invite_desc,
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          Button(
            onPressed: () {},
            leading: const Icon(
              LucideIcons.plus,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
            child: Text(tp.send_invite),
          ),
        ],
      ),
    );
  }
}

class _StatusTabsDemoCard extends StatelessWidget {
  const _StatusTabsDemoCard();

  static Widget _buildTab(BuildContext context, String label, bool selected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = selected
        ? colorScheme.onPrimary.toValue()
        : colorScheme.onSurface.toValue();

    return Container(
      padding: const .symmetric(vertical: _Size.s8, horizontal: _Size.s12),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.toValue()
            : material.Colors.transparent,
        border: selected
            ? null
            : Border.all(
                color: colorScheme.surfaceContainerHigh.toValue(),
              ),
        borderRadius: .circular(_Size.s20),
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: _Size.s6,
        children: [
          Icon(
            LucideIcons.refreshCw,
            iconStyle: CoreIconStyle(
              size: _Size.s14,
              color: _iconColor(iconColor),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: _Size.s12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Wrap(
        spacing: _Size.s8,
        runSpacing: _Size.s8,
        children: [
          _buildTab(context, tp.syncing, true),
          _buildTab(context, tp.updating, false),
          _buildTab(context, tp.loading_tab, false),
        ],
      ),
    );
  }
}

class _ChatInputDemoCard extends StatelessWidget {
  const _ChatInputDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.surfaceContainerHigh.toValue();
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Row(
        spacing: _Size.s8,
        children: [
          Container(
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s8),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: const Icon(
              LucideIcons.plus,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
          Expanded(
            // Demo TextField - no state management needed.
            child: TextField(
              placeholder: Text(
                tp.send_message_placeholder,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s8),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: const Icon(
              LucideIcons.mic,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRangeDemoCard extends StatelessWidget {
  const _PriceRangeDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(tp.price_range).semiBold(),
          const SizedBox(height: _Size.s4),
          Text(
            tp.min_value,
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          Slider(
            onChanged: (_) {},
            value: _DemoValues.sliderValue,
          ),
        ],
      ),
    );
  }
}

class _UrlInputDemoCard extends StatelessWidget {
  const _UrlInputDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceColor = colorScheme.onSurface.toValue();
    final iconTint = _iconColor(onSurfaceColor);

    return _DemoCard(
      child: Container(
        padding: const .symmetric(vertical: _Size.s10, horizontal: _Size.s12),
        decoration: BoxDecoration(
          border: .all(
            color: colorScheme.surfaceContainerHigh.toValue(),
          ),
          borderRadius: .circular(_Size.s8),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.info,
              iconStyle: CoreIconStyle(
                size: _Size.s16,
                color: iconTint,
              ),
            ),
            const SizedBox(width: _Size.s8),
            Expanded(
              child: Text(
                'https://',
                style: TextStyle(color: onSurfaceColor),
              ),
            ),
            Icon(
              LucideIcons.star,
              iconStyle: CoreIconStyle(
                size: _Size.s16,
                color: iconTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSearchDemoCard extends StatelessWidget {
  const _AiSearchDemoCard();

  static Widget _buildChip(BuildContext context, String label, bool hasIcon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const .symmetric(vertical: _Size.s6, horizontal: _Size.s10),
      decoration: BoxDecoration(
        border: .all(
          color: colorScheme.surfaceContainerHigh.toValue(),
        ),
        borderRadius: .circular(_Size.s16),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          if (hasIcon) ...[
            Icon(
              LucideIcons.globe,
              iconStyle: CoreIconStyle(
                size: _Size.s12,
                color: _iconColor(colorScheme.onSurface.toValue()),
              ),
            ),
            const SizedBox(width: _Size.s4),
          ],
          Text(label, style: const TextStyle(fontSize: _Size.s12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        spacing: _Size.s12,
        children: [
          Container(
            padding: const .symmetric(
              vertical: _Size.s8,
              horizontal: _Size.s12,
            ),
            decoration: BoxDecoration(
              border: .all(
                color: colorScheme.surfaceContainerHigh.toValue(),
              ),
              borderRadius: .circular(_Size.s8),
            ),
            child: Row(
              spacing: _Size.s8,
              children: [
                Icon(
                  LucideIcons.paperclip,
                  iconStyle: CoreIconStyle(
                    size: _Size.s16,
                    color: _iconColor(onSurface.toValue()),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Ask, search, or make anything...',
                    style: TextStyle(
                      color: onSurface.withValues(
                        alpha: _Opacity.half,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: _Size.s8,
            runSpacing: _Size.s8,
            crossAxisAlignment: .center,
            children: [
              _buildChip(context, tp.auto, false),
              _buildChip(context, tp.all_sources, true),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.toValue(),
                  borderRadius: .circular(_Size.s16),
                ),
                width: _Size.s32,
                height: _Size.s32,
                child: Icon(
                  LucideIcons.arrowUp,
                  iconStyle: CoreIconStyle(
                    size: _Size.s16,
                    color: _iconColor(colorScheme.onPrimary.toValue()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TwoFactorAuthDemoCard extends StatelessWidget {
  const _TwoFactorAuthDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Row(
        children: [
          Expanded(
            child: Text(tp.two_factor_auth),
          ),
          Button(
            onPressed: () {},
            child: Text(tp.enable),
          ),
        ],
      ),
    );
  }
}

class _ProfileVerifiedDemoCard extends StatelessWidget {
  const _ProfileVerifiedDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _DemoCard(
      child: Container(
        padding: const .all(12),
        decoration: BoxDecoration(
          border: .all(
            color: colorScheme.surfaceContainerHigh.toValue(),
          ),
          borderRadius: .circular(_Size.s8),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.success.toValue(),
                shape: .circle,
              ),
              width: _Size.s24,
              height: _Size.s24,
              child: const Icon(
                LucideIcons.check,
                iconStyle: CoreIconStyle(
                  size: _Size.s14,
                  color: CoreColor(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(width: _Size.s12),
            const Expanded(
              child: Text('Your profile has been verified.'),
            ),
            Icon(
              LucideIcons.chevronRight,
              iconStyle: CoreIconStyle(
                color: _iconColor(colorScheme.onSurface.toValue()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComputeEnvironmentDemoCard extends StatelessWidget {
  const _ComputeEnvironmentDemoCard();

  static Widget _buildOption(
    BuildContext context,
    String title,
    String desc,
    bool selected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary.toValue();
    final onPrimary = colorScheme.onPrimary;
    final onSurface = colorScheme.onSurface;
    final resolvedOnPrimary = onPrimary.toValue();
    final resolvedOnSurface = onSurface.toValue();
    final unselectedBorderColor = colorScheme.surfaceContainerHigh.toValue();

    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: selected ? primaryColor : material.Colors.transparent,
        border: .all(
          color: selected ? primaryColor : unselectedBorderColor,
        ),
        borderRadius: .circular(_Size.s8),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: _Size.s4,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? resolvedOnPrimary : resolvedOnSurface,
                    fontWeight: .w600,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: selected
                        ? onPrimary.withValues(
                            alpha: _Opacity.faded,
                          )
                        : onSurface.withValues(
                            alpha: _Opacity.faded,
                          ),
                    fontSize: _Size.s12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: .all(
                color: selected ? resolvedOnPrimary : unselectedBorderColor,
                width: selected ? _Size.s4 : 1,
              ),
              shape: .circle,
            ),
            width: _Size.s16,
            height: _Size.s16,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(tp.compute_env).semiBold(),
          const SizedBox(height: _Size.s4),
          const Text(
            'Select the compute environment for your cluster.',
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          _buildOption(
            context,
            tp.kubernetes,
            'Run GPU workloads on a K8s configured cluster.',
            true,
          ),
          const SizedBox(height: _Size.s8),
          _buildOption(
            context,
            tp.virtual_machine,
            'Access a VM configured cluster. (Coming soon)',
            false,
          ),
        ],
      ),
    );
  }
}

class _NumberStepperDemoCard extends StatelessWidget {
  const _NumberStepperDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dividerColor = colorScheme.surfaceContainerHigh.toValue();
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: _Size.s4,
              children: [
                Text(tp.number_of_gpus).semiBold(),
                Text(
                  tp.add_more_later,
                ).bodySmall().onSurface(),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: .all(
                color: dividerColor,
              ),
              borderRadius: .circular(_Size.s8),
            ),
            child: Row(
              children: [
                Container(
                  alignment: .center,
                  width: _Size.s40,
                  height: _Size.s36,
                  child: const Text('8'),
                ),
                Container(
                  color: dividerColor,
                  width: 1,
                  height: _Size.s36,
                ),
                Container(
                  alignment: .center,
                  width: _Size.s36,
                  height: _Size.s36,
                  child: const Icon(
                    LucideIcons.minus,
                    iconStyle: CoreIconStyle(size: _Size.s16),
                  ),
                ),
                Container(
                  color: dividerColor,
                  width: 1,
                  height: _Size.s36,
                ),
                Container(
                  alignment: .center,
                  width: _Size.s36,
                  height: _Size.s36,
                  child: const Icon(
                    LucideIcons.plus,
                    iconStyle: CoreIconStyle(size: _Size.s16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSettingDemoCard extends StatelessWidget {
  const _ToggleSettingDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: _Size.s4,
              children: [
                Text(
                  tp.wallpaper_tinting,
                ).semiBold(),
                Text(
                  tp.allow_wallpaper_tint,
                ).bodySmall().onSurface(),
              ],
            ),
          ),
          Toggle(onChanged: (_) {}, value: true),
        ],
      ),
    );
  }
}

class _EmailActionsDemoCard extends StatelessWidget {
  const _EmailActionsDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.surfaceContainerHigh.toValue();
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Wrap(
        spacing: _Size.s8,
        runSpacing: _Size.s8,
        crossAxisAlignment: .center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s8),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: const Icon(
              LucideIcons.arrowLeft,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
          Button(
            onPressed: () {},
            size: .sm,
            child: Text(tp.archive),
          ),
          Button(
            onPressed: () {},
            size: .sm,
            child: Text(tp.report),
          ),
          Button(
            onPressed: () {},
            size: .sm,
            child: Text(tp.snooze),
          ),
          Container(
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s8),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: const Icon(
              LucideIcons.ellipsis,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationDemoCard extends StatelessWidget {
  const _PaginationDemoCard();

  static Widget _buildPageButton(
    BuildContext context,
    String label,
    bool selected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      alignment: .center,
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.toValue()
            : material.Colors.transparent,
        border: .all(
          color: colorScheme.surfaceContainerHigh.toValue(),
        ),
        borderRadius: .circular(_Size.s8),
      ),
      width: _Size.s32,
      height: _Size.s32,
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? colorScheme.onPrimary.toValue()
              : colorScheme.onSurface.toValue(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.surfaceContainerHigh.toValue();

    return _DemoCard(
      child: Wrap(
        alignment: .center,
        spacing: _Size.s4,
        runSpacing: _Size.s4,
        children: [
          _buildPageButton(context, '1', true),
          _buildPageButton(context, '2', false),
          _buildPageButton(context, '3', false),
          const SizedBox(width: _Size.s4),
          Container(
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s8),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: const Icon(
              LucideIcons.arrowLeft,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s8),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: const Icon(
              LucideIcons.arrowRight,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveyDemoCard extends StatelessWidget {
  const _SurveyDemoCard();

  static Widget _buildChoice(
    BuildContext context,
    String label,
    bool selected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const .symmetric(vertical: _Size.s8, horizontal: _Size.s12),
      decoration: BoxDecoration(
        border: .all(
          color: selected
              ? colorScheme.primary.toValue()
              : colorScheme.surfaceContainerHigh.toValue(),
        ),
        borderRadius: .circular(_Size.s20),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          if (selected) ...[
            Icon(
              LucideIcons.circleCheck,
              iconStyle: CoreIconStyle(
                size: _Size.s16,
                color: _iconColor(colorScheme.primary.toValue()),
              ),
            ),
            const SizedBox(width: _Size.s6),
          ],
          Text(label, style: const TextStyle(fontSize: _Size.s12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(tp.how_hear_about_us).semiBold(),
          const SizedBox(height: _Size.s4),
          const Text(
            'Select the option that best describes how...',
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          Wrap(
            spacing: _Size.s8,
            runSpacing: _Size.s8,
            children: [
              _buildChoice(
                context,
                tp.social_media,
                true,
              ),
              _buildChoice(
                context,
                tp.search_engine,
                false,
              ),
              _buildChoice(context, tp.referral, false),
              _buildChoice(context, tp.other, false),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProcessingDemoCard extends StatelessWidget {
  const _ProcessingDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        children: [
          const SizedBox.square(
            dimension: _Size.s32,
            child: Loading(),
          ),
          const SizedBox(height: _Size.s16),
          Text(tp.processing_request).semiBold(),
          const SizedBox(height: _Size.s4),
          const Text(
            'Please wait while we process your request.',
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          Button(
            onPressed: () {},
            child: Text(tp.cancel),
          ),
        ],
      ),
    );
  }
}

class _StorageUsageDemoCard extends StatelessWidget {
  const _StorageUsageDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.surfaceContainerHigh.toValue();
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s8),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: const Icon(
              LucideIcons.plus,
              iconStyle: CoreIconStyle(size: _Size.s16),
            ),
          ),
          const SizedBox(width: _Size.s12),
          Container(
            padding: const .symmetric(
              vertical: _Size.s6,
              horizontal: _Size.s10,
            ),
            decoration: BoxDecoration(
              border: .all(color: borderColor),
              borderRadius: .circular(_Size.s16),
            ),
            child: Text(
              tp.auto,
              style: const TextStyle(fontSize: _Size.s12),
            ),
          ),
          const Spacer(),
          Text(
            '52% used',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: _Opacity.faded),
              fontSize: _Size.s12,
            ),
          ),
          const SizedBox(width: _Size.s8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.toValue(),
              borderRadius: .circular(_Size.s16),
            ),
            width: _Size.s32,
            height: _Size.s32,
            child: Icon(
              LucideIcons.arrowUp,
              iconStyle: CoreIconStyle(
                size: _Size.s16,
                color: _iconColor(colorScheme.onPrimary.toValue()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsernameInputDemoCard extends StatelessWidget {
  const _UsernameInputDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceColor = colorScheme.onSurface.toValue();

    return _DemoCard(
      child: Container(
        padding: const .symmetric(vertical: _Size.s10, horizontal: _Size.s12),
        decoration: BoxDecoration(
          border: .all(
            color: colorScheme.surfaceContainerHigh.toValue(),
          ),
          borderRadius: .circular(_Size.s8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '@coui_user',
                style: TextStyle(color: onSurfaceColor),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: onSurfaceColor,
                shape: .circle,
              ),
              width: _Size.s20,
              height: _Size.s20,
              child: Icon(
                LucideIcons.check,
                iconStyle: CoreIconStyle(
                  size: _Size.s12,
                  color: _iconColor(colorScheme.surface.toValue()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsCheckboxDemoCard extends StatelessWidget {
  const _TermsCheckboxDemoCard();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Row(
        spacing: _Size.s12,
        children: [
          Checkbox(
            onChanged: (_) {},
            checked: true,
          ),
          const Expanded(
            child: Text('I agree to the terms and conditions'),
          ),
        ],
      ),
    );
  }
}

class _AddContextDemoCard extends StatelessWidget {
  const _AddContextDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        spacing: _Size.s12,
        children: [
          Container(
            padding: const .symmetric(
              vertical: _Size.s6,
              horizontal: _Size.s10,
            ),
            decoration: BoxDecoration(
              border: .all(
                color: colorScheme.surfaceContainerHigh.toValue(),
              ),
              borderRadius: .circular(_Size.s16),
            ),
            child: Row(
              mainAxisSize: .min,
              spacing: _Size.s6,
              children: [
                Icon(
                  LucideIcons.atSign,
                  iconStyle: CoreIconStyle(
                    size: _Size.s14,
                    color: _iconColor(colorScheme.onSurface.toValue()),
                  ),
                ),
                Text(
                  tp.add_context,
                  style: const TextStyle(fontSize: _Size.s12),
                ),
              ],
            ),
          ),
          // Demo TextField - no state management needed.
          TextField(
            placeholder: const Text('Ask, search, or make anything...'),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsDemoCard extends StatelessWidget {
  const _SearchResultsDemoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _DemoCard(
      child: Container(
        padding: const .symmetric(vertical: _Size.s10, horizontal: _Size.s12),
        decoration: BoxDecoration(
          border: .all(
            color: colorScheme.surfaceContainerHigh.toValue(),
          ),
          borderRadius: .circular(_Size.s8),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              iconStyle: CoreIconStyle(
                size: _Size.s16,
                color: _iconColor(colorScheme.onSurface.toValue()),
              ),
            ),
            const SizedBox(width: _Size.s8),
            Expanded(
              child: Text(
                'Search...',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(
                    alpha: _Opacity.half,
                  ),
                ),
              ),
            ),
            Text(
              '12 results',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(
                  alpha: _Opacity.faded,
                ),
                fontSize: _Size.s12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingAddressDemoCard extends StatelessWidget {
  const _BillingAddressDemoCard();

  @override
  Widget build(BuildContext context) {
    final tp = t.widgetbook.theme_preview;

    return _DemoCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(tp.billing_address).semiBold(),
          const SizedBox(height: _Size.s4),
          Text(
            tp.billing_address_desc,
          ).bodySmall().onSurface(),
          const SizedBox(height: _Size.s16),
          Row(
            spacing: _Size.s8,
            children: [
              Checkbox(
                onChanged: (_) {},
                checked: true,
              ),
              Text(tp.same_as_shipping),
            ],
          ),
          const SizedBox(height: _Size.s16),
          Text(tp.comments).semiBold(),
          const SizedBox(height: _Size.s8),
          SizedBox(
            height: _Size.s80,
            // Demo TextField - no state management needed.
            child: TextField(
              placeholder: Text(tp.add_comments),
            ),
          ),
          const SizedBox(height: _Size.s16),
          Wrap(
            spacing: _Size.s8,
            runSpacing: _Size.s8,
            children: [
              Button(
                onPressed: () {},
                child: Text(tp.submit),
              ),
              Button(
                onPressed: () {},
                child: Text(tp.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
