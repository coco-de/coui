import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:coui_lints/src/rules/avoid_dynamic_event_target_rule.dart';
import 'package:coui_lints/src/rules/avoid_framework_import_rule.dart';
import 'package:coui_lints/src/rules/avoid_hardcoded_chrome_literal_rule.dart';
import 'package:coui_lints/src/rules/avoid_hardcoded_duration_rule.dart';
import 'package:coui_lints/src/rules/avoid_incomplete_copy_with_rule.dart';
import 'package:coui_lints/src/rules/avoid_local_token_constant_rule.dart';
import 'package:coui_lints/src/rules/avoid_material_icon_glyph_rule.dart';
import 'package:coui_lints/src/rules/avoid_override_prefixed_resolved_field_rule.dart';
import 'package:coui_lints/src/rules/pass_theme_geometry_rule.dart';
import 'package:coui_lints/src/rules/prefer_handle_prefixed_callback_rule.dart';
import 'package:coui_lints/src/rules/prefer_k_prefixed_global_constant_rule.dart';
import 'package:coui_lints/src/rules/prefer_stacks_and_position_rule.dart';
import 'package:coui_lints/src/rules/prefer_text_chain_rule.dart';

/// The CoUI analyzer plugin — registers every CoUI lint rule.
///
/// Rules are registered as *lint* rules (disabled by default), so each must
/// be explicitly enabled under `plugins: coui_lints: diagnostics:` in the
/// workspace root `analysis_options.yaml`. See README.md for the full rule
/// list and rationale.
class CoUIPlugin extends Plugin {
  @override
  String get name => 'CoUI plugin';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(AvoidFrameworkImportRule())
      ..registerLintRule(PreferStacksAndPositionRule())
      ..registerLintRule(AvoidMaterialIconGlyphRule())
      ..registerLintRule(PreferTextChainRule())
      ..registerLintRule(AvoidHardcodedDurationRule())
      ..registerLintRule(AvoidHardcodedChromeLiteralRule())
      ..registerLintRule(AvoidDynamicEventTargetRule())
      ..registerLintRule(AvoidOverridePrefixedResolvedFieldRule())
      ..registerLintRule(AvoidLocalTokenConstantRule())
      ..registerLintRule(AvoidIncompleteCopyWithRule())
      ..registerLintRule(PreferKPrefixedGlobalConstantRule())
      ..registerLintRule(PreferHandlePrefixedCallbackRule())
      ..registerLintRule(PassThemeGeometryRule());
  }
}
