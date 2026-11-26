import 'package:coui_web/coui_web.dart';
// chip_group_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/display/chip_group/chip_group_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

// #6472 — the header stacks the title over the selection hint (two lines, 2
// apart), the title is the 15px label role in SemiBold and the hint the 12px
// body role in `onSurfaceVariant`. Same values the Flutter twin paints
// (`chip_group_header_test.dart` there).

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

ResolvedChipGroup _resolved(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveChipGroup(context, showFade: true);
}

Set<String> _classes(String className) =>
    className.split(' ').where((cls) => cls.isNotEmpty).toSet();

void main() {
  group('ChipGroup header — resolver', () {
    testComponents('the header is a start-aligned column', (tester) async {
      expect(
        _classes(_resolved(tester).header.className),
        {'flex', 'flex-col', 'items-start'},
      );
    });

    testComponents('the title ↔ hint gap is 2', (tester) async {
      expect(_resolved(tester).titleHintGapStyle.size, CoreSpace.space2);
    });

    testComponents('the title is the 15px label role in SemiBold', (
      tester,
    ) async {
      final title = _resolved(tester).title;
      expect(_classes(title.className), {'text-label-xl', 'text-on-surface'});
      expect(title.inlineStyles?.properties, {'font-weight': '600'});
    });

    testComponents('the hint is the 12px body role in onSurfaceVariant', (
      tester,
    ) async {
      final hint = _resolved(tester).hint;
      expect(
        _classes(hint.className),
        {'text-body-xs', 'text-on-surface-variant'},
      );
      expect(hint.inlineStyles, isNull);
    });
  });

  group('ChipGroup header — rendered DOM', () {
    testComponents('title, a 2 gap, then the hint, stacked in one column', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ChipGroup<String>(
          items: const ['A', 'B'],
          title: const Text('Filter'),
          selectionHint: const Text('Pick up to two'),
          chipBuilder:
              (item, {required selected, required enabled, required onTap}) =>
                  Chip(
                    label: item,
                    selected: selected,
                    enabled: enabled,
                    onTap: onTap,
                  ),
        ),
      );

      final header = find
          .tag('div')
          .evaluate()
          .map((element) => element.component as DomComponent)
          .where(
            (element) =>
                _classes(element.classes ?? '').containsAll(
                  ['flex-col', 'items-start'],
                ) &&
                !_classes(element.classes ?? '').contains('inline-flex'),
          )
          .toList();
      expect(header, hasLength(1), reason: 'exactly one header column');

      final children = header.single.children!;
      expect(children, hasLength(3));
      final gap = children[1];
      expect(gap, isA<Gap>());
      expect((gap as Gap).gapStyle?.size, CoreSpace.space2);
    });
  });
}
