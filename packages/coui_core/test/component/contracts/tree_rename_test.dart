import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTreeRenameRules.committedLabel', () {
    const node = CoreTreeNode(id: 'lib/main.dart', label: 'main.dart');

    test('reports a changed name trimmed of surrounding whitespace', () {
      expect(
        CoreTreeRenameRules.committedLabel(node, '  app.dart \t'),
        'app.dart',
      );
    });

    test('reports nothing for an empty or blank name', () {
      expect(CoreTreeRenameRules.committedLabel(node, ''), isNull);
      expect(CoreTreeRenameRules.committedLabel(node, '   '), isNull);
    });

    test('reports nothing when the name did not change', () {
      expect(CoreTreeRenameRules.committedLabel(node, 'main.dart'), isNull);
      expect(CoreTreeRenameRules.committedLabel(node, ' main.dart '), isNull);
    });

    test('keeps inner whitespace and reports a case-only change', () {
      expect(
        CoreTreeRenameRules.committedLabel(node, 'my main.dart'),
        'my main.dart',
      );
      expect(
        CoreTreeRenameRules.committedLabel(node, 'Main.dart'),
        'Main.dart',
      );
    });
  });

  group('CoreTreeRenameRules.selectionEnd', () {
    test('a leaf selects the stem before its last dot', () {
      expect(CoreTreeRenameRules.selectionEnd('main.dart', isBranch: false), 4);
      expect(
        CoreTreeRenameRules.selectionEnd('archive.tar.gz', isBranch: false),
        11,
      );
    });

    test('a dot-file or a name without a dot selects everything', () {
      expect(
        CoreTreeRenameRules.selectionEnd('.gitignore', isBranch: false),
        10,
      );
      expect(CoreTreeRenameRules.selectionEnd('Makefile', isBranch: false), 8);
    });

    test('a branch selects everything, dots included', () {
      expect(CoreTreeRenameRules.selectionEnd('v1.2', isBranch: true), 4);
    });
  });

  group('CoreTreeRenameRules.fieldStyle', () {
    test('takes the xs height, the row corner and the label typography', () {
      const label = CoreTextStyle.token(CoreTextStyles.labelMedium);
      final style = CoreTreeRenameRules.fieldStyle(label);

      expect(style.height, CoreControlSize.heightXs);
      expect(style.borderRadius, CoreTreeStyle.defaultBorderRadius);
      expect(
        style.padding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space4),
      );
      // Role and size are the label's own…
      expect(style.baseTextStyle?.token, CoreTextStyles.labelMedium);
      // …the colour is stated by the rules, not inherited from the label.
      expect(style.baseTextStyle?.color, CoreTreeRenameRules.fieldTextColor);
      expect(
        CoreTreeRenameRules.fieldTextColor,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('the typed text stays onSurface under a dimmer label colour', () {
      const dimmer = CoreTextStyle.token(
        CoreTextStyles.codeSm,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      );
      final style = CoreTreeRenameRules.fieldStyle(dimmer);

      expect(style.baseTextStyle?.token, CoreTextStyles.codeSm);
      expect(
        style.baseTextStyle?.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });
  });
}
