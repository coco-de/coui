// The category colours as the Web stylesheet carries them — read back out of
// what `ThemeConfig` emits and held to the category table, mode by mode.
//
// The stylesheet is generated from the same scheme Flutter reads, so the
// expectation here is not that scheme: it is the table, read with the
// config's own pure white and black. Each place the Web states a mode — the
// `:root` block, both dark forms, both high-contrast blocks — is read on its
// own, so a slot that falls out of any one of them shows here, and so does
// a slot no Tailwind class can name.
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../helpers/brand_fixture.dart';

/// Every category slot's name, hue by hue.
final List<String> _kNames = [
  for (final color in CoreCategoryColor.values)
    for (final slot in CoreCategorySlot.values) slot.cssName(color),
];

/// A config, the white and black its strong labels read, and which category
/// slots its raise governs in a brightness.
typedef _Config = ({
  ThemeConfig config,
  CoreColor white,
  CoreColor black,
  Set<String> Function(CoreBrightness) governed,
});

/// The category slots whose value the table changes under high contrast —
/// what a raise that writes only its disagreements governs.
Set<String> _moved(
  CoreBrightness brightness, {
  required CoreColor white,
  required CoreColor black,
}) => {
  for (final color in CoreCategoryColor.values)
    for (final slot in CoreCategorySlot.values)
      if (_value(color, slot, (brightness, false), white, black) !=
          _value(color, slot, (brightness, true), white, black))
        slot.cssName(color),
};

/// The `R G B` the table states for one slot in one mode.
String _value(
  CoreCategoryColor color,
  CoreCategorySlot slot,
  (CoreBrightness, bool) mode,
  CoreColor white,
  CoreColor black,
) {
  final c = CoreCategoryPalette.valueOf(
    color,
    slot,
    mode.$1,
    highContrast: mode.$2,
    white: white,
    black: black,
  );

  return '${c.red} ${c.green} ${c.blue}';
}

final _kConfigs = <String, _Config>{
  // CoUI raises by the difference between its normal and high-contrast
  // tables.
  'CoUI': (
    config: ThemeConfig.defaults(),
    white: CouiColorPresets.palette.white,
    black: CouiColorPresets.palette.black,
    governed: (brightness) => _moved(
      brightness,
      white: CouiColorPresets.palette.white,
      black: CouiColorPresets.palette.black,
    ),
  ),
  // The standard raise writes every category slot.
  'brand': (
    config: ThemeConfig(kBrandFixturePalette),
    white: kBrandFixturePalette.neutral.pureWhite,
    black: kBrandFixturePalette.neutral.pureBlack,
    governed: (_) => _kNames.toSet(),
  ),
};

/// The `--coui-*` declarations of [body], by name without the prefix.
Map<String, String> _declarations(String body) => {
  for (final m in RegExp(r'--coui-([a-z0-9-]+):\s*([^;}]+)').allMatches(body))
    m[1]!: m[2]!.trim(),
};

/// The body of the first rule [pattern] matches in [css].
String _bodyOf(String css, RegExp pattern) {
  final match = pattern.firstMatch(css);
  expect(match, isNotNull, reason: 'no rule matches ${pattern.pattern}');

  return match!.group(1)!;
}

/// A high-contrast block, by the selector it raises.
RegExp _highContrast(String selector) => RegExp(
  '@media \\(prefers-contrast:more\\)\\{${RegExp.escape(selector)}\\{(.*?)\\}\\}',
  dotAll: true,
);

void main() {
  for (final MapEntry(key: name, value: entry) in _kConfigs.entries) {
    group('$name: the stylesheet states the category table', () {
      final css = entry.config.cssVariables;

      // Each place the Web states a mode — read inside its test — with the
      // mode it states.
      final blocks = <String, (String Function(), (CoreBrightness, bool))>{
        ':root': (
          () => _bodyOf(css, RegExp(r':root \{(.*?)\n\}', dotAll: true)),
          (.light, false),
        ),
        '[data-theme="dark"]': (
          () => entry.config.darkVariableBlock,
          (.dark, false),
        ),
        'prefers-color-scheme: dark': (
          () => entry.config.darkAutoVariableBlock,
          (.dark, false),
        ),
        'high contrast, light': (
          () => _bodyOf(
            css,
            _highContrast(':root:root:where(:not([data-theme="dark"]))'),
          ),
          (.light, true),
        ),
        'high contrast, dark': (
          () => _bodyOf(css, _highContrast(':root:root[data-theme="dark"]')),
          (.dark, true),
        ),
      };

      for (final MapEntry(key: block, value: (body, mode)) in blocks.entries) {
        test(block, () {
          final vars = _declarations(body());
          final carried = {
            for (final slot in _kNames)
              if (vars.containsKey(slot)) slot,
          };
          // A normal block states every slot; a high-contrast block only
          // what the raise governs, leaving the rest to `:root`.
          final want = mode.$2 ? entry.governed(mode.$1) : _kNames.toSet();
          expect(want, isNotEmpty);
          expect(carried, want);

          final drift = <String>[];
          for (final color in CoreCategoryColor.values) {
            for (final slot in CoreCategorySlot.values) {
              final key = slot.cssName(color);
              if (!carried.contains(key)) continue;
              final value = _value(color, slot, mode, entry.white, entry.black);
              if (vars[key] != value) {
                drift.add('$key: table $value, stylesheet ${vars[key]}');
              }
            }
          }
          expect(drift, isEmpty, reason: drift.join('\n'));
        });
      }

      test('Tailwind registers every slot as a colour', () {
        final registered = {
          for (final m in RegExp(
            r'"([a-z0-9-]+)":"rgb\(var\(--coui-([a-z0-9-]+)\)\)"',
          ).allMatches(entry.config.tailwindConfig))
            if (m[1] == m[2]) m[1]!,
        };

        expect(registered, containsAll(_kNames));
      });
    });
  }
}
