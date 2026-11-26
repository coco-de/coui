// Writes the data the CoUI Brand Color Generator Figma plugin reads, from
// the code that owns it — so the plugin's palette, semantic and contrast
// tabs show what `CoreBrand.fromColor` renders, not a hand-kept copy.
//
// The plugin lives in the designer's Figma account (a generative plugin),
// outside this repository. Its colour engine embeds this output; when CoUI's
// palette or mapping changes, rerun this tool and paste the result into the
// plugin's engine.
//
//   dart run tool/export_brand_generator_data.dart > brand_generator_data.json
//
// `palette` is CoUI's fixed neutral and status ramps (hex). `semantic` is
// CoUI's own mapping for every slot the plugin lists, as primitive refs per
// mode `[Light, Dark, HCLight, HCDark]` (`neutral/700`, `success/600`,
// `base/white`) — refs, so the plugin's status correction can re-point them
// at a turned ramp. The primary and tertiary families, `surface-tint`,
// `inverse-primary` and `focus-ring` are omitted: the brand's CTA rule
// states those.
//
// `--vectors <hex,...>` instead prints `CoreBrandSchemeSource`'s resolved
// hex for those brand colours — the reference the plugin engine is checked
// against.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';

const _kBrandRule = {
  'primary',
  'on-primary',
  'primary-hover',
  'primary-pressed',
  'primary-container',
  'on-primary-container',
  'primary-fixed',
  'primary-fixed-dim',
  'on-primary-fixed',
  'on-primary-fixed-variant',
  'primary-text',
  'primary-text-large',
  'surface-tint',
  'inverse-primary',
  'focus-ring',
  'tertiary',
  'on-tertiary',
  'tertiary-container',
  'on-tertiary-container',
  'tertiary-fixed',
  'tertiary-fixed-dim',
  'on-tertiary-fixed',
  'on-tertiary-fixed-variant',
};

// Every mode's slots as `#RRGGBB`, read through the Web emitter's slot
// vocabulary — the one walk every semantic emitter shares, so no slot can
// be missing here that the CSS has.
List<Map<String, String>> _modes(CoreSchemeSource s) {
  Map<String, String> read(CoreColorScheme scheme, CoreBrightness b) => {
    for (final e in PrimitiveCssGenerator.semanticVars(
      scheme.resolved(b),
    ).entries)
      e.key.substring('--coui-'.length): _rgbToHex(e.value),
  };

  return [
    read(s.light(), CoreBrightness.light),
    read(s.dark(), CoreBrightness.dark),
    read(s.highContrastLight(), CoreBrightness.light),
    read(s.highContrastDark(), CoreBrightness.dark),
  ];
}

String _rgbToHex(String triplet) {
  final [r, g, b] = triplet.split(' ').map(int.parse).toList();
  final rgb = (r << 16) | (g << 8) | b;

  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

void main(List<String> args) {
  final slotsFile = args.indexOf('--slots');
  final slots = slotsFile >= 0
      ? (jsonDecode(File(args[slotsFile + 1]).readAsStringSync()) as List)
            .cast<String>()
      : null;
  final vectors = args.indexOf('--vectors');
  if (vectors >= 0) {
    final out = <String, Object>{};
    for (final hex in args[vectors + 1].split(',')) {
      final modes = _modes(
        CoreBrandSchemeSource.fromColor(CoreColor.fromHex(hex)),
      );
      out[hex] = {
        for (final slot in slots ?? modes.first.keys)
          slot: [for (final m in modes) m[slot]?.toUpperCase()],
      };
    }
    stdout.writeln(const JsonEncoder.withIndent(' ').convert(out));
    return;
  }

  const palette = CouiColorPresets.palette;
  final byHex = {
    for (final e in palette.primitives.entries)
      e.value.toHex().toUpperCase(): e.key,
  };
  final modes = _modes(CouiColorPresets.source);
  final semantic = <String, List<String>>{};
  for (final slot in slots ?? modes.first.keys) {
    if (_kBrandRule.contains(slot)) continue;
    semantic[slot] = [
      for (final m in modes)
        byHex[m[slot]!.toUpperCase()] ??
            (throw StateError('$slot ${m[slot]} is not a CoUI primitive')),
    ];
  }
  Map<String, String> ramp(Map<int, CoreColor> steps) => {
    for (final e in steps.entries) '${e.key}': e.value.toHex().toUpperCase(),
  };
  stdout.writeln(
    const JsonEncoder.withIndent(' ').convert({
      'palette': {
        'neutral': ramp(palette.neutral.steps),
        'success': ramp(palette.success.steps),
        'info': ramp(palette.info.steps),
        'warning': ramp(palette.warning.steps),
        'error': ramp(palette.error.steps),
      },
      'semantic': semantic,
    }),
  );
}
