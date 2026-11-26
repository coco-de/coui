import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/primitive_colors.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:coui_core/src/color/scheme_source.dart';
import 'package:coui_core/src/color/semantic_mapping_set.dart';
import 'package:coui_core/src/color/syntax_palette.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// Generates CSS custom properties from a [CoreSchemeSource].
///
/// Outputs `--coui-{layer}-{name}: value;` for both Primitive
/// and Semantic layers, enabling Tailwind/CSS integration.
///
/// Usage:
/// ```dart
/// final css = PrimitiveCssGenerator.toCssBlockFrom(
///   CouiColorPresets.source,
///   brightness: 'light',
/// );
/// // :root { --coui-neutral-50: 249 250 251; ... }
/// ```
///
/// The [PrimitiveColors] entry points ([generate], `generateSemantic*`,
/// [toCssBlock]) are the same functions for a brand's generated palette —
/// they bind it to its mapping and forward here.
class PrimitiveCssGenerator {
  const PrimitiveCssGenerator._();

  /// The Primitive CSS variables of [source] —
  /// `--coui-<family>-<step>` for every `'<family>/<step>'` entry of
  /// [CoreSchemeSource.primitives], in that order.
  static Map<String, String> primitiveVars(CoreSchemeSource source) => {
    for (final entry in source.primitives.entries)
      '--coui-${entry.key.replaceAll('/', '-')}': _hex(entry.value),
  };

  /// Generate all Primitive CSS variables of a generated palette as a map
  /// (`--coui-neutral-pure-white` … `--coui-error-darkest`).
  static Map<String, String> generate(PrimitiveColors colors) =>
      primitiveVars(CorePrimitiveSchemeSource(colors));

  /// The category primitives as `'R G B'` triplets, keyed by their
  /// primitive name (`category/red/light-fill`) — all 117, in
  /// [CoreCategoryPalette.primitives] order.
  ///
  /// Brand-less: every brand reads the same values, so these are never
  /// part of any source's [primitiveVars], and they are not CSS variables —
  /// the Web emits no `--coui-category-*` primitive. The Figma export
  /// writes them into its shared Primitives group and checks every slot it
  /// links there by name against them.
  static Map<String, String> categoryPrimitiveTriplets() => {
    for (final entry in CoreCategoryPalette.primitives.entries)
      entry.key: _hex(entry.value),
  };

  /// The brand-less syntax primitives as `'R G B'` triplets, keyed by
  /// their primitive name (`syntax/purple/light`) — all six, in
  /// [CoreSyntaxPalette.primitives] order.
  ///
  /// Brand-less like [categoryPrimitiveTriplets], and for the same reason
  /// never part of any source's [primitiveVars] nor a CSS variable — the
  /// Web emits only the semantic `--coui-syntax-*` slots. The Figma export
  /// writes them into its shared Primitives group and checks every slot it
  /// links there by name against them.
  static Map<String, String> syntaxPrimitiveTriplets() => {
    for (final entry in CoreSyntaxPalette.primitives.entries)
      entry.key: _hex(entry.value),
  };

  /// The Semantic CSS variables of [source] for one mode — the normal
  /// scheme for [brightness], or its high-contrast counterpart.
  static Map<String, String> semanticVarsFor(
    CoreSchemeSource source,
    CoreBrightness brightness, {
    bool highContrast = false,
  }) {
    final scheme = switch ((brightness, highContrast)) {
      (.light, false) => source.light(),
      (.dark, false) => source.dark(),
      (.light, true) => source.highContrastLight(),
      (.dark, true) => source.highContrastDark(),
    };
    return semanticVars(scheme.resolved(brightness));
  }

  /// The Semantic CSS variables high contrast governs for [brightness], at
  /// their high-contrast values.
  ///
  /// "Governs" means what [CoreSchemeSource.raiseContrast] writes, not what
  /// happens to come out different. The theme seat raises a base a surface
  /// style has already bent, so every slot the raise writes takes its
  /// high-contrast value over the style — including a slot the raise pins
  /// to its normal value (the standard light raise does this to
  /// `errorPressed`). The Web block has to write that same set for the
  /// preference to outrank a style on the same slots. A set chosen by value
  /// inequality drops the pinned slots, and there the style's bend would
  /// survive on the Web and lose on Flutter.
  ///
  /// The set is read off the raise itself: it is handed a scheme whose
  /// every slot is a sentinel, and the variables that come back changed are
  /// the governed ones. A hand-kept list would fall behind the moment a
  /// mapping raised a slot it did not name. Two sentinels, so a raise that
  /// happens to write one of them is still caught by the other. The
  /// `accent` pair rides with the tertiary slots it reads, and the surface
  /// tones drop out whenever the raise leaves them to the base.
  static Map<String, String> semanticVarsRaised(
    CoreSchemeSource source,
    CoreBrightness brightness,
  ) {
    final governed = <String>{};
    for (final sentinel in _kRaiseProbes) {
      final probe = CoreColorScheme.uniform(sentinel);
      final before = semanticVars(probe.resolved(brightness));
      final after = semanticVars(
        source.raiseContrast(probe, brightness).resolved(brightness),
      );
      for (final entry in after.entries) {
        if (before[entry.key] != entry.value) governed.add(entry.key);
      }
    }
    final raised = semanticVarsFor(source, brightness, highContrast: true);

    return {
      for (final entry in raised.entries)
        if (governed.contains(entry.key)) entry.key: entry.value,
    };
  }

  /// Generate Semantic layer CSS variables (Light mode).
  ///
  /// [mapping] is the brand's Primitive → Semantic interpretation — the
  /// same palette answers differently under another mapping, so callers
  /// that render a specific brand pass that brand's set.
  static Map<String, String> generateSemanticLight(
    PrimitiveColors c, {
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) => semanticVarsFor(mapping.bind(c), .light);

  /// Generate Semantic layer CSS variables (Dark mode).
  static Map<String, String> generateSemanticDark(
    PrimitiveColors c, {
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) => semanticVarsFor(mapping.bind(c), .dark);

  /// Generate Semantic layer CSS variables (high-contrast Light mode).
  ///
  /// Figma modes have no cascade — a mode with a value missing for a slot
  /// is *unresolved*, not "inherits the sibling mode". So unlike the Web
  /// `@media (prefers-contrast: more)` block, which emits only what
  /// [semanticVarsRaised] reports and lets the rest fall through `:root`,
  /// this walks the full vocabulary — the unchanged slots are still
  /// present, restating the same alias Light already uses.
  static Map<String, String> generateSemanticHighContrastLight(
    PrimitiveColors c, {
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) => semanticVarsFor(mapping.bind(c), .light, highContrast: true);

  /// Generate Semantic layer CSS variables (high-contrast Dark mode).
  ///
  /// See [generateSemanticHighContrastLight] — same full-vocabulary reason.
  static Map<String, String> generateSemanticHighContrastDark(
    PrimitiveColors c, {
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) => semanticVarsFor(mapping.bind(c), .dark, highContrast: true);

  /// Reads the Semantic CSS-var vocabulary off a [ResolvedColorScheme].
  ///
  /// The single walk every semantic emitter shares. Reading the vocabulary
  /// off the same scheme the mapping produces — rather than restating the
  /// mapping's decisions as a second, hand-synced table — makes the CSS and
  /// the scheme unable to drift apart, and lets every mode (normal, high
  /// contrast, a surface style's bent scheme) reuse the exact same walk.
  static Map<String, String> semanticVars(ResolvedColorScheme scheme) => {
    for (final entry in _semanticSlotReaders.entries)
      '--coui-${entry.key}': _hex(entry.value(scheme)),
  };

  /// CSS-var key (without the `--coui-` prefix) -> [ResolvedColorScheme]
  /// slot reader. The single source of "what a Semantic mode is" — every
  /// semantic emitter walks this same 127-entry vocabulary (the 125 scheme
  /// slots plus the `accent` pair), so a mode can differ in *value* (a
  /// design decision, made in the mapping) but never in *which slots exist*
  /// (a bug).
  static final Map<String, CoreColor Function(ResolvedColorScheme)>
  _semanticSlotReaders = {
    // Surface
    'surface': (s) => s.surface,
    'surface-dim': (s) => s.surfaceDim,
    'surface-bright': (s) => s.surfaceBright,
    'surface-container-lowest': (s) => s.surfaceContainerLowest,
    'surface-container-low': (s) => s.surfaceContainerLow,
    'surface-container': (s) => s.surfaceContainer,
    'surface-container-high': (s) => s.surfaceContainerHigh,
    'surface-container-highest': (s) => s.surfaceContainerHighest,
    'on-surface': (s) => s.onSurface,
    'on-surface-variant': (s) => s.onSurfaceVariant,
    'placeholder': (s) => s.placeholder,
    'link': (s) => s.link,
    'on-surface-subtle': (s) => s.onSurfaceSubtle,
    'surface-raised': (s) => s.surfaceRaised,
    'surface-tint': (s) => s.surfaceTint,
    // Primary
    'primary': (s) => s.primary,
    'on-primary': (s) => s.onPrimary,
    'primary-container': (s) => s.primaryContainer,
    'on-primary-container': (s) => s.onPrimaryContainer,
    // Primary Fixed
    'primary-fixed': (s) => s.primaryFixed,
    'primary-fixed-dim': (s) => s.primaryFixedDim,
    'on-primary-fixed': (s) => s.onPrimaryFixed,
    'on-primary-fixed-variant': (s) => s.onPrimaryFixedVariant,
    // Primary as text (normal / large — different WCAG floors)
    'primary-text': (s) => s.primaryText,
    'primary-text-large': (s) => s.primaryTextLarge,
    // Secondary
    'secondary': (s) => s.secondary,
    'on-secondary': (s) => s.onSecondary,
    'secondary-container': (s) => s.secondaryContainer,
    'on-secondary-container': (s) => s.onSecondaryContainer,
    // Secondary Fixed
    'secondary-fixed': (s) => s.secondaryFixed,
    'secondary-fixed-dim': (s) => s.secondaryFixedDim,
    'on-secondary-fixed': (s) => s.onSecondaryFixed,
    'on-secondary-fixed-variant': (s) => s.onSecondaryFixedVariant,
    // Tertiary
    'tertiary': (s) => s.tertiary,
    'on-tertiary': (s) => s.onTertiary,
    'tertiary-container': (s) => s.tertiaryContainer,
    'on-tertiary-container': (s) => s.onTertiaryContainer,
    // Tertiary Fixed
    'tertiary-fixed': (s) => s.tertiaryFixed,
    'tertiary-fixed-dim': (s) => s.tertiaryFixedDim,
    'on-tertiary-fixed': (s) => s.onTertiaryFixed,
    'on-tertiary-fixed-variant': (s) => s.onTertiaryFixedVariant,
    // Accent — the tertiary fill pair under a name products can bind.
    // A copy of the same resolved channels, so light / dark / high
    // contrast stay honest without a second scheme field. Surface-style
    // and high-contrast blocks restate both names together.
    'accent': (s) => s.tertiary,
    'on-accent': (s) => s.onTertiary,
    // Error
    'error': (s) => s.error,
    'on-error': (s) => s.onError,
    'error-container': (s) => s.errorContainer,
    'on-error-container': (s) => s.onErrorContainer,
    'error-strong': (s) => s.errorStrong,
    'focus-ring': (s) => s.focusRing,
    'primary-hover': (s) => s.primaryHover,
    'primary-pressed': (s) => s.primaryPressed,
    'secondary-hover': (s) => s.secondaryHover,
    'secondary-pressed': (s) => s.secondaryPressed,
    'error-pressed': (s) => s.errorPressed,
    // Success
    'success': (s) => s.success,
    'on-success': (s) => s.onSuccess,
    'success-container': (s) => s.successContainer,
    'on-success-container': (s) => s.onSuccessContainer,
    // Warning
    'warning': (s) => s.warning,
    'on-warning': (s) => s.onWarning,
    'warning-container': (s) => s.warningContainer,
    'on-warning-container': (s) => s.onWarningContainer,
    // Info
    'info': (s) => s.info,
    'on-info': (s) => s.onInfo,
    'info-container': (s) => s.infoContainer,
    'on-info-container': (s) => s.onInfoContainer,
    'error-icon': (s) => s.errorIcon,
    'success-icon': (s) => s.successIcon,
    'warning-icon': (s) => s.warningIcon,
    'info-icon': (s) => s.infoIcon,
    // Outline
    'outline': (s) => s.outline,
    'outline-variant': (s) => s.outlineVariant,
    'outline-subtle': (s) => s.outlineSubtle,
    // Inverse
    'inverse-surface': (s) => s.inverseSurface,
    'inverse-on-surface': (s) => s.inverseOnSurface,
    'inverse-primary': (s) => s.inversePrimary,
    // Special
    'shadow': (s) => s.shadow,
    'surface-highlight': (s) => s.surfaceHighlight,
    'scrim': (s) => s.scrim,
    // Disabled
    'disabled-content': (s) => s.disabledContent,
    'disabled-container': (s) => s.disabledContainer,
    'disabled-outline': (s) => s.disabledOutline,
    // Syntax
    'syntax-keyword': (s) => s.syntaxKeyword,
    'syntax-type': (s) => s.syntaxType,
    'syntax-function': (s) => s.syntaxFunction,
    'syntax-string': (s) => s.syntaxString,
    // Category — every hue's five slots, hue by hue. Walked off the enums
    // rather than listed: the slot names and the readers are the ones the
    // tokens carry, so this cannot name a slot the catalog does not.
    for (final color in CoreCategoryColor.values)
      for (final slot in CoreCategorySlot.values)
        color.token(slot).name: (s) => color.token(slot).read(s)!,
  };

  /// Generate DaisyUI legacy CSS variable aliases.
  ///
  /// Maps deprecated DaisyUI variables to new CoUI Semantic
  /// variables for backward compatibility.
  static Map<String, String> generateDaisyUiAliases() {
    return {
      // DaisyUI → CoUI Semantic
      '--p': 'var(--coui-primary)',
      '--pc': 'var(--coui-on-primary)',
      '--s': 'var(--coui-secondary)',
      '--sc': 'var(--coui-on-secondary)',
      '--a': 'var(--coui-tertiary)',
      '--ac': 'var(--coui-on-tertiary)',
      '--n': 'var(--coui-outline)',
      '--nc': 'var(--coui-on-surface)',
      '--b1': 'var(--coui-surface)',
      '--b2': 'var(--coui-surface-container)',
      '--b3': 'var(--coui-surface-container-high)',
      '--bc': 'var(--coui-on-surface)',
      '--in': 'var(--coui-info)',
      '--inc': 'var(--coui-on-info)',
      '--su': 'var(--coui-success)',
      '--suc': 'var(--coui-on-success)',
      '--wa': 'var(--coui-warning)',
      '--wac': 'var(--coui-on-warning)',
      '--er': 'var(--coui-error)',
      '--erc': 'var(--coui-on-error)',
    };
  }

  /// Generate shadcn/ui legacy CSS variable aliases.
  ///
  /// Maps deprecated shadcn variables to new CoUI Semantic
  /// variables for backward compatibility.
  static Map<String, String> generateShadcnAliases() {
    return {
      '--background': 'var(--coui-surface)',
      '--foreground': 'var(--coui-on-surface)',
      '--card': 'var(--coui-surface)',
      '--card-foreground': 'var(--coui-on-surface)',
      '--popover': 'var(--coui-surface)',
      '--popover-foreground': 'var(--coui-on-surface)',
      '--primary': 'var(--coui-primary)',
      '--primary-foreground': 'var(--coui-on-primary)',
      '--secondary': 'var(--coui-secondary)',
      '--secondary-foreground': 'var(--coui-on-secondary)',
      '--muted': 'var(--coui-surface-container)',
      '--muted-foreground': 'var(--coui-on-surface-variant)',
      '--accent': 'var(--coui-tertiary)',
      '--accent-foreground': 'var(--coui-on-tertiary)',
      '--destructive': 'var(--coui-error)',
      '--destructive-foreground': 'var(--coui-on-error)',
      '--border': 'var(--coui-outline)',
      '--input': 'var(--coui-outline-variant)',
      '--ring': 'var(--coui-primary)',
    };
  }

  /// Generate a CSS `:root { ... }` block string for [source].
  ///
  /// Includes Primitive, Semantic, and legacy alias variables.
  static String toCssBlockFrom(
    CoreSchemeSource source, {
    String brightness = 'light',
  }) {
    final primitive = primitiveVars(source);
    final semantic = semanticVarsFor(
      source,
      brightness == 'dark' ? .dark : .light,
    );
    final daisyUi = generateDaisyUiAliases();
    final shadcn = generateShadcnAliases();

    final buffer = StringBuffer(':root {\n')
      ..writeln('  /* Primitive Colors */')
      ..writeAll(
        primitive.entries.map(
          (e) => '  ${e.key}: ${e.value};\n',
        ),
      )
      ..writeln()
      ..writeln('  /* Semantic Colors ($brightness) */')
      ..writeAll(
        semantic.entries.map(
          (e) => '  ${e.key}: ${e.value};\n',
        ),
      )
      ..writeln()
      ..writeln('  /* DaisyUI Legacy (deprecated) */')
      ..writeAll(
        daisyUi.entries.map(
          (e) => '  ${e.key}: ${e.value};\n',
        ),
      )
      ..writeln()
      ..writeln('  /* shadcn/ui Legacy (deprecated) */')
      ..writeAll(
        shadcn.entries.map(
          (e) => '  ${e.key}: ${e.value};\n',
        ),
      )
      ..writeln('}');
    return buffer.toString();
  }

  /// Generate a CSS `:root { ... }` block string for a generated palette,
  /// read through [mapping].
  static String toCssBlock(
    PrimitiveColors colors, {
    String brightness = 'light',
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) => toCssBlockFrom(mapping.bind(colors), brightness: brightness);

  /// RGB channel format for Tailwind opacity modifier support.
  /// Output: '98 0 238' (no commas, no rgb() wrapper).
  static String _hex(CoreColor c) => '${c.red} ${c.green} ${c.blue}';
}

/// The sentinels [PrimitiveCssGenerator.semanticVarsRaised] fills a probe
/// scheme with. Not design values — two colours far apart, so a raise that
/// writes one of them still differs from the other.
const List<CoreColor> _kRaiseProbes = [
  CoreColor.fromRGB(1, 2, 3),
  CoreColor.fromRGB(254, 253, 252),
];
