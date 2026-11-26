import 'package:coui_web/coui_web.dart';
// chip_group_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/display/chip_group/chip_group_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveChipGroup` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// Whole classes, not substrings, so an assertion pins the exact set a
/// chrome emits rather than one fragment of it.
Set<String> _classes(String className) =>
    className.split(' ').where((cls) => cls.isNotEmpty).toSet();

ChipGroup<String> _group(CoreChipGroupLayout layout) => ChipGroup<String>(
  items: const ['All', 'Frontend', 'Backend', 'Mobile'],
  layout: layout,
  chipBuilder: (item, {required selected, required enabled, required onTap}) =>
      Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        onTap: onTap,
      ),
);

/// Every rendered `<div>` whose classes carry [cls], in document order.
List<DomComponent> _divsWith(String cls) => find
    .tag('div')
    .evaluate()
    .map((element) => element.component as DomComponent)
    .where((element) => _classes(element.classes ?? '').contains(cls))
    .toList();

void main() {
  // CSS layout widths are not computed by the VM tests, so these hold the
  // *classes* that make the browser's sizing come out right. The widths
  // themselves were measured in a real browser (see the fix's issue): a
  // shrink-to-fit root whose scroll viewport is a cyclic `w-full` takes the
  // chip row's full width as its `min-content`, which leaves the viewport as
  // wide as its content and nothing to scroll.
  group(
    'ChipGroup scroll layout — the root is clamped to the available width',
    () {
      testComponents(
        'the root hugs its content but never outgrows the parent '
        '(Flutter Column(mainAxisSize: min) under a max-width constraint)',
        (tester) async {
          final context = _themedContext(tester);

          expect(
            _classes(resolveChipGroup(context, showFade: true).root.className),
            {'inline-flex', 'flex-col', 'max-w-full', 'min-w-0'},
          );
        },
      );

      testComponents(
        'the scroll row is as wide as its chips, not as wide as the viewport',
        (tester) async {
          final context = _themedContext(tester);

          expect(
            _classes(
              resolveChipGroup(context, showFade: true).scrollInner.className,
            ),
            {'flex', 'flex-row', 'flex-nowrap', 'w-max'},
          );
        },
      );

      testComponents(
        'the wrap row is untouched — it already breaks at the available width, '
        "so it must not pick up the scroll row's max-content width",
        (tester) async {
          final context = _themedContext(tester);

          expect(
            _classes(resolveChipGroup(context, showFade: true).wrap.className),
            {'flex', 'flex-wrap'},
          );
        },
      );

      testComponents(
        'the clamp does not depend on showFade',
        (tester) async {
          final context = _themedContext(tester);

          expect(
            resolveChipGroup(context, showFade: false).root.className,
            resolveChipGroup(context, showFade: true).root.className,
          );
          expect(
            resolveChipGroup(context, showFade: false).scrollInner.className,
            resolveChipGroup(context, showFade: true).scrollInner.className,
          );
        },
      );
    },
  );

  group('ChipGroup scroll layout — the rendered DOM carries the clamp', () {
    testComponents(
      'a scroll group renders the clamped root and a max-content row inside '
      'the scroll viewport',
      (tester) async {
        pumpWithTheme(tester, _group(CoreChipGroupLayout.scroll));

        // A chip's own root is `inline-flex max-w-full` too — only the
        // group root is also a column.
        final roots = _divsWith('flex-col')
            .where(
              (element) => _classes(element.classes!).contains('max-w-full'),
            )
            .toList();
        expect(roots, hasLength(1), reason: 'exactly one clamped group root');
        expect(
          _classes(roots.single.classes!),
          containsAll(['inline-flex', 'flex-col', 'max-w-full', 'min-w-0']),
        );

        final rows = _divsWith('w-max');
        expect(rows, hasLength(1), reason: 'exactly one max-content row');
        expect(_classes(rows.single.classes!), contains('flex-nowrap'));
        expect(_divsWith('flex-wrap'), isEmpty);
      },
    );

    testComponents(
      'a wrap group renders no max-content row',
      (tester) async {
        pumpWithTheme(tester, _group(CoreChipGroupLayout.wrap));

        expect(_divsWith('w-max'), isEmpty);
        expect(_divsWith('flex-nowrap'), isEmpty);
        expect(_divsWith('flex-wrap'), hasLength(1));
      },
    );
  });
}
