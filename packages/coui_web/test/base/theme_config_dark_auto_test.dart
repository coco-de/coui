import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  final config = ThemeConfig.defaults();

  group('dark mode reachable without a theme controller', () {
    // What this covers: the dark palette was only ever emitted behind
    // `[data-theme="dark"]`, and the sole writer of that attribute is
    // `CoUIThemeController` at runtime. A statically rendered site had no
    // path to dark mode at all — it would have had to ship JS whose only
    // job is to set one attribute before first paint.
    test('emits a prefers-color-scheme rule', () {
      expect(
        config.darkAutoVariableBlock,
        startsWith('@media (prefers-color-scheme:dark){'),
      );
    });

    test('carries the same variables as the attribute form', () {
      // Both forms are generated from `semanticDarkVars`, so a palette
      // change reaches the OS-preference path without a second edit.
      final attr = config.darkVariableBlock;
      final auto = config.darkAutoVariableBlock;

      for (final entry in config.semanticDarkVars.entries) {
        final decl = '${entry.key}:${entry.value}';
        expect(attr, contains(decl));
        expect(auto, contains(decl));
      }
    });

    test('an explicit light choice outranks the OS preference', () {
      // Without this guard a visitor who deliberately picked light would be
      // dragged back to dark by their OS — the toggle would look broken.
      expect(
        config.darkAutoVariableBlock,
        contains(':root:not([data-theme="light"])'),
      );
    });

    test('does not smuggle in the attribute selector', () {
      // If this block also matched `[data-theme="dark"]`, injecting both
      // would duplicate every declaration for no benefit.
      expect(
        config.darkAutoVariableBlock,
        isNot(contains('[data-theme="dark"]')),
      );
    });
  });
}
