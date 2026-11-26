/// What each typography role draws in each of the `Semantic/ Typography`
/// collection's modes — the one table both exporters read.
///
/// Why it is shared: the tokens export writes these sizes into the
/// collection's `font-size/<role>` and `letter-spacing/<role>` variables, and
/// the components export hands them to the plugin so a check that reads a
/// consumer file can compare a literal against what a text style would draw
/// in THAT file's mode. A consumer file usually draws in Mobile, the
/// collection's first mode, where the display and headline roles are a step
/// or two smaller than the code scale. A second copy of the stepping beside
/// the variables would let the check judge against sizes the canvas no
/// longer draws, and nothing would fail.
///
/// Nothing here states a size or a tracking: each mode is the code scale at
/// its viewport tier (`CoreTypography.atTier`, the step both platforms draw
/// at the same width), and tracking is the rule the scale's sans roles state
/// (`CoreTrackingRule`).
library;

import 'package:coui_core/coui_core.dart';

/// The modes, in the order the collection lists them, each with the viewport
/// tier it draws — the first is the one a node draws in when nothing above it
/// chooses.
const kTypographyTiers = <(String, CoreBreakpointTier)>[
  ('Mobile', CoreBreakpointTier.mobile),
  ('Tablet', CoreBreakpointTier.tablet),
  ('Desktop', CoreBreakpointTier.desktop),
];

/// The mode names of [kTypographyTiers], in the same order.
final List<String> kTypographyModes = [
  for (final (mode, _) in kTypographyTiers) mode,
];

/// The tracking rule `CoreTypography.coui` states, or [fail] saying why the
/// scale no longer states a two-step rule.
///
/// Read before anything that steps a tier: `CoreTypography.atTier` tracks a
/// stepped role by this rule, so a scale that broke it would otherwise stop
/// inside the step with a less direct message.
CoreTrackingRule couiTrackingRule({
  required Never Function(String problem) fail,
}) {
  try {
    return CoreTrackingRule.coui;
  } on FormatException catch (e) {
    fail(e.message);
  }
}

/// Per-role font sizes as [mobile, tablet, desktop], keyed the way the
/// semantic variables are (`display-large`) and listed in
/// `CoreTextStyles.values` order.
///
/// Desktop IS the code scale — `CoreTypography.coui` as authored — and each
/// smaller mode is that scale at its tier: the display and headline roles
/// step down, the rest stay flat. Weight and line-height come from the
/// scale's roles and do not vary by mode.
Map<String, List<double>> typographyFontSizesByMode() {
  final scales = [
    for (final (_, tier) in kTypographyTiers) CoreTypography.coui.atTier(tier),
  ];
  return {
    for (final token in CoreTextStyles.values)
      token.name: [for (final scale in scales) token.read(scale).fontSize!],
  };
}

/// Each role's font size and tracking (em) in every mode, keyed by the
/// role's leaf and then by mode name — what the components export writes
/// beside each role's own metrics.
///
/// Tracking is per mode because a role tracks by the size it is rendered at
/// ([CoreTrackingRule]): `headline-small` is 16px on Mobile and tracks the
/// looser step there. [fail] stops the export when the scale no longer states
/// the rule; the caller decides how a stop looks.
Map<String, Map<String, Map<String, double>>> typographyModeMetrics({
  required Never Function(String problem) fail,
}) {
  final tracking = couiTrackingRule(fail: fail);
  final sizes = typographyFontSizesByMode();
  final roles = {
    for (final t in CoreTextStyles.values) t.name: t.read(CoreTypography.coui),
  };
  return {
    for (final e in sizes.entries)
      e.key: {
        for (var i = 0; i < kTypographyModes.length; i++)
          kTypographyModes[i]: {
            'fontSize': e.value[i],
            'letterSpacing': tracking.forRole(
              roles[e.key] ?? fail('no CoreTextStyles role named ${e.key}'),
              e.value[i],
            ),
          },
      },
  };
}
