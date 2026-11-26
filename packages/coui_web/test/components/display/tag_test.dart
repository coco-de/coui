import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/tag/tag.dart';
import 'package:coui_web/src/components/display/tag/tag_style.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

DomComponent _root() =>
    find.tag('span').evaluate().first.component as DomComponent;

void main() {
  group('Tag defaults', () {
    test('a bare tag is gray, subtle, md — the Core contract defaults', () {
      const tag = Tag(child: Component.text('Design'));
      expect(tag.color, CoreTagContract.defaultColor);
      expect(tag.color, CoreCategoryColor.gray);
      expect(tag.emphasis, CoreTagEmphasis.defaultEmphasis);
      expect(tag.size, CoreTagSize.defaultSize);
    });
  });

  group('Tag rendering', () {
    for (final emphasis in CoreTagEmphasis.values) {
      for (final size in CoreTagSize.values) {
        testComponents('renders ${emphasis.name} ${size.name} from the '
            'resolver', (tester) async {
          final tag = Tag(
            color: CoreCategoryColor.purple,
            emphasis: emphasis,
            size: size,
            child: const Component.text('Design'),
          );
          pumpWithTheme(tester, tag);
          final resolved = resolveTag(
            find.byType(Tag).evaluate().single,
            color: tag.color,
            emphasis: emphasis,
            size: size,
          );
          final root = _root();
          expect(root.classes, resolved.root.className);
          expect(
            root.styles?.properties,
            resolved.root.inlineStyles?.properties,
          );
          expect(find.text('Design'), findsOneComponent);
        });
      }
    }

    testComponents('display only — no role, no tabindex, no listeners, no '
        'scoped style', (tester) async {
      pumpWithTheme(tester, const Tag(child: Component.text('Design')));
      final root = _root();
      expect(root.attributes?['role'], isNull);
      expect(root.attributes?['tabindex'], isNull);
      expect(root.events, isNull);
      expect(root.id, isNull);
      expect(find.tag('style'), findsNothing);
    });

    testComponents('caller classes, id and attributes reach the root', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Tag(
          id: 'my-tag',
          classes: 'ms-2',
          attributes: {'data-testid': 'tag'},
          child: Component.text('Design'),
        ),
      );
      final root = _root();
      expect(root.id, 'my-tag');
      expect(root.classes, endsWith(' ms-2'));
      expect(root.attributes?['data-testid'], 'tag');
    });

    test('withStyle merges a patch into tagStyle', () {
      const base = Tag(
        tagStyle: CoreTagStyle(minHeight: 30),
        child: Component.text('Design'),
      );
      final chained = base.withStyle(
        const CoreTagStyle(borderRadius: CoreBorderRadius.all(2)),
      );
      expect(chained.tagStyle!.minHeight, 30);
      expect(chained.tagStyle!.borderRadius, const CoreBorderRadius.all(2));
    });
  });
}
