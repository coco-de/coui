import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;

import 'parity_theme.dart';
import 'parity_tier.dart';
import 'probe_spec.dart';

/// One cell of the verification matrix — one (component, variant, theme,
/// surfaceStyle) combination to capture on both platforms and compare.
///
/// Source: `.bmad/architecture-*.md` Data Architecture → `MatrixEntry`.
class MatrixEntry {
  MatrixEntry({
    required this.component,
    required this.variant,
    required this.theme,
    required this.surfaceStyle,
    required this.tier,
    required this.probes,
  }) : key = '$component-$variant-${theme.name}-${surfaceStyle.name}';

  /// Reconstructs a [MatrixEntry] from [toJson]'s output.
  factory MatrixEntry.fromJson(Map<String, Object?> json) {
    final theme = ParityTheme.tryParse(json['theme']! as String);
    if (theme == null) {
      throw FormatException('알 수 없는 theme: ${json['theme']}');
    }
    final tier = ParityTier.tryParse(json['tier']! as String);
    if (tier == null) {
      throw FormatException('알 수 없는 tier: ${json['tier']}');
    }
    final surfaceStyleName = json['surfaceStyle']! as String;
    CoreSurfaceStyleId? surfaceStyle;
    for (final id in CoreSurfaceStyleId.values) {
      if (id.name == surfaceStyleName) {
        surfaceStyle = id;
        break;
      }
    }
    if (surfaceStyle == null) {
      throw FormatException('알 수 없는 surfaceStyle: $surfaceStyleName');
    }

    return MatrixEntry(
      component: json['component']! as String,
      variant: json['variant']! as String,
      theme: theme,
      surfaceStyle: surfaceStyle,
      tier: tier,
      probes: [
        for (final raw in (json['probes']! as List))
          ProbeSpec.fromJson((raw as Map).cast()),
      ],
    );
  }

  /// `<component>-<variant>-<theme>-<surfaceStyle>` — the artifact/baseline
  /// filename stem (see `tool/parity/src/baseline/artifact_name.dart`).
  final String key;

  /// Catalog slug, e.g. `card`.
  final String component;

  /// Variant name, `default` included.
  final String variant;

  final ParityTheme theme;

  final CoreSurfaceStyleId surfaceStyle;

  final ParityTier tier;

  final List<ProbeSpec> probes;

  Map<String, Object?> toJson() => {
    'key': key,
    'component': component,
    'variant': variant,
    'theme': theme.name,
    'surfaceStyle': surfaceStyle.name,
    'tier': tier.name,
    'probes': probes.map((p) => p.toJson()).toList(),
  };

  @override
  String toString() => 'MatrixEntry($key, tier=${tier.name})';
}
