import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:docs_core/site_head.dart';
import 'package:test/test.dart';

void main() {
  final rules = docsPreviewStyles().map((rule) => rule.toCss()).toList();

  String rule(String selector) => rules.singleWhere(
    (rule) => rule.startsWith('$selector {'),
  );

  test('preview panes use the shared surface token in both themes', () {
    expect(rule('.preview-pane'), contains('background: rgb(var(--coui-surface))'));
    expect(
      rules.where((rule) => rule.startsWith('[data-theme="dark"] .preview-pane {')),
      isEmpty,
      reason: 'a dark-only fallback must not replace the theme surface',
    );

    final theme = ThemeConfig.defaults();
    for (final (variables, preset) in [
      (theme.semanticLightVars, CoreThemePresets.previewLight),
      (theme.semanticDarkVars, CoreThemePresets.previewDark),
    ]) {
      final argb = preset.colorScheme.surface!.argb;
      final channels = '${(argb >> 16) & 255} ${(argb >> 8) & 255} ${argb & 255}';
      expect(variables['--coui-surface'], channels);
    }
  });

  test('liquid glass keeps its specific backdrop in each theme', () {
    for (final selector in [
      '[data-coui-style="liquidGlass"] .preview-pane.preview-web',
      '[data-theme="dark"][data-coui-style="liquidGlass"] .preview-pane.preview-web',
    ]) {
      expect(rule(selector), contains('gradient('));
    }
  });
}
