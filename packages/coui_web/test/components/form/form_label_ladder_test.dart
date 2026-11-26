// FormLabel's size ladder on Web — 13 / 500 (`label-medium`) through `md`,
// 14 / 500 (`label-large`) from `lg`. The label family is a role class, so the
// ladder is read off the class the resolver emits; the Flutter twin reads the
// same ladder as a font size.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

void main() {
  const expected = {
    CoreComponentSize.xs: 'text-label-medium',
    CoreComponentSize.sm: 'text-label-medium',
    CoreComponentSize.md: 'text-label-medium',
    CoreComponentSize.lg: 'text-label-large',
    CoreComponentSize.xl: 'text-label-large',
    CoreComponentSize.xl2: 'text-label-large',
  };

  for (final entry in expected.entries) {
    testComponents('${entry.key.name} reads ${entry.value}', (tester) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((c) => context = c));

      final classes = resolveFormLabel(
        context,
        size: entry.key,
      ).root.className.split(' ');

      expect(classes, contains(entry.value));
      // Exactly one `text-label-*` role class, the one this size names.
      expect(
        classes.where((c) => c.startsWith('text-label-')),
        [entry.value],
      );
    });
  }
}
