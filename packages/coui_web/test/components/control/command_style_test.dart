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

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedCommand _resolve(BuildContext context, CoreCommandStyle style) =>
    resolveCommand(context, commandStyle: style);

void main() {
  group('Command chain — raw transparent override', () {
    // The `.transparent` chain getter (Command.transparent — see
    // command.dart's CommandStyleChain, shared 1:1 by every T1 chain
    // component) sets `backgroundColor: CoreColor.transparent`, a
    // token-less sentinel (`token == null`). `buildRootClassName` used to
    // call `backgroundColor.tailwindColor` unconditionally, and that
    // getter null-checks `token!.name` — a raw override crashed the whole
    // `Command` build ("Error while building Command: Unexpected null
    // value") instead of just omitting the `bg-` class, the documented
    // behaviour of `CoreColorTailwind.isTransparent`.
    testComponents(
      'a transparent backgroundColor no longer throws — the bg- class is '
      'dropped entirely rather than null-checking a token-less colour',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreCommandStyle(backgroundColor: .transparent);
        final resolved = _resolve(context, style);
        expect(resolved.root.className, isNot(contains('bg-')));
      },
    );

    testComponents(
      'a transparent borderColor no longer throws — the border- colour '
      'class is dropped, the structural classes stay',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreCommandStyle(borderColor: .transparent);
        final resolved = _resolve(context, style);
        expect(resolved.root.className, isNot(contains('border-')));
        expect(resolved.root.className, contains(WebLayout.flex));
      },
    );

    testComponents(
      'a token backgroundColor override still emits the bg-* class (no '
      'regression on the normal, class-safe path)',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreCommandStyle(
          backgroundColor: CoreColor.token(CoreColors.primary),
        );
        final resolved = _resolve(context, style);
        expect(resolved.root.className, contains('bg-primary'));
      },
    );

    testComponents(
      'a transparent itemHighlightColor / itemTextStyle colour no longer '
      'throws building the highlighted-item cell — the bg-/text- classes '
      'are dropped',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreCommandStyle(
          itemHighlightColor: .transparent,
          itemTextStyle: CoreTextStyle(color: .transparent),
        );
        final resolved = _resolve(context, style);
        expect(resolved.itemActive.className, isNot(contains('bg-')));
        expect(resolved.itemActive.className, isNot(contains('text-')));
      },
    );

    testComponents(
      'a transparent itemForegroundColor no longer throws building the '
      'idle (not-highlighted) item cell',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreCommandStyle(itemForegroundColor: .transparent);
        final resolved = _resolve(context, style);
        expect(resolved.itemEnabled.className, isNot(contains('text-')));
      },
    );
  });

  group('Command colour slots', () {
    testComponents(
      'the panel stands on the raised face in every presentation, with the '
      'line each presentation states',
      (tester) async {
        final context = _themedContext(tester);
        final inline = resolveCommand(context);
        expect(inline.root.className, contains('bg-surface-bright'));
        expect(inline.root.className, contains('border-outline-variant'));

        final dialog = resolveCommand(context, presentation: .dialog);
        expect(dialog.root.className, contains('bg-surface-bright'));
        expect(dialog.root.className, contains('border-outline-subtle'));

        // fullscreen states no fill of its own — it reads the shared one.
        final full = resolveCommand(context, presentation: .fullscreen);
        expect(full.root.className, contains('bg-surface-bright'));
      },
    );

    testComponents(
      'the footer follows the panel and the group heading reads the '
      'subtle on-surface tone',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(context);
        expect(resolved.footer.className, contains('bg-surface-bright'));
        expect(resolved.heading.className, contains('text-on-surface-subtle'));
      },
    );

    testComponents(
      'the group heading is the labelXs role as it stands — 11 Medium, '
      'no weight stated on top of it',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(context);
        expect(resolved.heading.className, contains('text-label-xs'));
        expect(resolved.heading.className, isNot(contains('font-')));
        expect(
          resolved.heading.inlineStyles?.properties.containsKey('font-weight'),
          isNot(true),
        );
      },
    );
  });

  group('Command redesign — presentation / size / rules', () {
    testComponents(
      'the inline shape binds its panel width and list height to the '
      'CoreLayout scale as Tailwind keys, not inline rem',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(context);
        expect(resolved.root.className, contains('min-w-layout240'));
        expect(resolved.list.className, contains('min-h-layout240'));
        expect(resolved.list.className, contains('max-h-layout320'));
        expect(
          resolved.root.inlineStyles?.properties ?? {},
          isNot(contains('min-width')),
        );
      },
    );

    testComponents(
      'the dialog shape lifts the list ceiling and caps the panel at '
      'layout640; fullscreen drops both bounds and the radius',
      (tester) async {
        final context = _themedContext(tester);
        final dialog = resolveCommand(context, presentation: .dialog);
        expect(dialog.root.className, contains('max-w-layout640'));
        expect(dialog.list.className, contains('max-h-layout400'));
        expect(dialog.root.inlineStyles?.properties['box-shadow'], isNotNull);

        final full = resolveCommand(context, presentation: .fullscreen);
        expect(full.root.className, isNot(contains('max-w-')));
        expect(full.list.className, isNot(contains('max-h-')));
        expect(
          full.root.inlineStyles?.properties['border-width'],
          contains('0'),
        );
      },
    );

    testComponents(
      'an off-scale panel width override goes inline and drops the class',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(
          context,
          commandStyle: const CoreCommandStyle(panelMinWidth: 300),
        );
        expect(resolved.root.className, isNot(contains('min-w-layout')));
        expect(resolved.root.inlineStyles?.properties['min-width'], '18.75rem');
      },
    );

    testComponents(
      'size sm shrinks the search row height and the row inset',
      (tester) async {
        final context = _themedContext(tester);
        final sm = resolveCommand(context, size: .sm);
        final md = resolveCommand(context);
        // The size rows of the control ladder, through the row variable a
        // density re-points.
        expect(
          sm.header.inlineStyles?.properties['height'],
          'var(--coui-control-height-32)',
        );
        expect(
          md.header.inlineStyles?.properties['height'],
          'var(--coui-control-height-40)',
        );
        expect(
          sm.itemEnabled.inlineStyles?.properties['padding'],
          isNot(md.itemEnabled.inlineStyles?.properties['padding']),
        );
      },
    );

    testComponents(
      'the active row is the surface-container fill and nothing else, '
      'and the scoped rules paint the hover / pressed washes on the row '
      'marker',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(context);
        expect(
          resolved.itemActive.className.split(' '),
          contains('bg-surface-container'),
        );
        // No accent bar: the active row names no tertiary ink anywhere.
        expect(resolved.itemActive.className, isNot(contains('tertiary')));
        expect(resolved.itemWash.className, isNot(contains('tertiary')));

        final rules = resolveCommandRules(context, scopeId: 'cmd-x');
        expect(rules.css, contains('#cmd-x .$kCommandRowMarker:hover'));
        expect(rules.css, contains('#cmd-x .$kCommandRowMarker:active'));
        expect(rules.css, contains('.$kCommandWashMarker'));
        expect(rules.css, contains('on-surface'));
      },
    );

    testComponents(
      'a disabled row reads the disabled-content token, not an opacity',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(context);
        expect(
          resolved.itemDisabled.className,
          contains('text-disabled-content'),
        );
        expect(resolved.itemDisabled.className, isNot(contains('opacity')));
      },
    );

    testComponents(
      'a row highlight, hover and pressed wash share the 8 corner',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(context);
        const eight = CoreBorderRadius.all(CoreRadius.radius8);
        final expected = eight.toValue();
        for (final chrome in [
          resolved.itemEnabled,
          resolved.itemActive,
          resolved.itemDisabled,
          resolved.itemWash,
        ]) {
          expect(chrome.inlineStyles?.properties['border-radius'], expected);
        }
      },
    );

    testComponents(
      'the two-line row reads Regular body roles, the description and the '
      'shortcut keep on-surface-variant, and the title keeps on-surface',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveCommand(context);
        // Description: 12 Regular in on-surface-variant — on-surface-subtle
        // falls under 4.5:1 on the active fill and the washes.
        expect(resolved.overline.className, contains('text-body-xs'));
        expect(resolved.overline.className, contains('on-surface-variant'));
        expect(resolved.overline.className, isNot(contains('subtle')));
        // Shortcut: 12 Regular, the same colour for the same reason.
        expect(resolved.shortcut.className, contains('text-body-xs'));
        expect(resolved.shortcut.className, contains('on-surface-variant'));
        expect(resolved.shortcut.className, isNot(contains('subtle')));
        // Title: a body role (not a title role), no semibold.
        expect(resolved.title.className, contains('text-body-medium'));
        expect(resolved.title.className, isNot(contains('text-title')));
        expect(resolved.title.className, isNot(contains('font-semibold')));
      },
    );

    testComponents(
      'the size ladder moves the title; the description is bodyXs on every '
      'rung',
      (tester) async {
        final context = _themedContext(tester);
        final sm = resolveCommand(context, size: .sm);
        final lg = resolveCommand(context, size: .lg);
        expect(sm.title.className, contains('text-body-small'));
        expect(sm.overline.className, contains('text-body-xs'));
        expect(lg.title.className, contains('text-body-medium'));
        expect(lg.overline.className, contains('text-body-xs'));
      },
    );
  });

  group('Command scope chips and hints', () {
    testComponents(
      'scope chips carry no border and an 8 corner; the footer hint is '
      'on-surface-subtle',
      (tester) async {
        final resolved = resolveCommand(_themedContext(tester), size: .sm);
        expect(resolved.scopeChipStyle.borderWidth, 0);
        expect(
          resolved.scopeChipStyle.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius8),
        );
        expect(
          resolved.footerLabel.className.split(' '),
          contains('text-on-surface-subtle'),
        );
      },
    );
  });
}
