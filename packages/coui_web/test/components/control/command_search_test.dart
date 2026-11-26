// The command palette trigger's Web contract: what it announces, which seat
// each part takes, and how the face follows size and state. The Flutter twin
// asserts the same behaviours against the rendered widget
// (`coui_flutter/test/components/control/command_search_test.dart`); this
// file asserts them against the SSR markup, where the announcement lives in
// attributes rather than a semantics node.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

/// The trigger element — the composed `Clickable`'s box.
const String _kTrigger = '[role="button"]';

void main() {
  group('CommandSearch announcement', () {
    testServer('an enabled trigger is a button and takes the tab stop', (
      tester,
    ) async {
      tester.pumpComponent(_host(CommandSearch(onPressed: () {})));
      final trigger = (await tester.request(
        '/',
      )).document!.querySelector(_kTrigger);

      expect(trigger, isNotNull);
      expect(trigger!.attributes['tabindex'], '0');
      expect(trigger.attributes['aria-disabled'], isNull);
    });

    testServer('a trigger with no handler is disabled and leaves the tab '
        'order, like any disabled button', (tester) async {
      tester.pumpComponent(_host(const CommandSearch(hint: 'Search')));
      final trigger = (await tester.request(
        '/',
      )).document!.querySelector(_kTrigger);

      expect(trigger!.attributes['aria-disabled'], 'true');
      expect(trigger.attributes['tabindex'], isNull);
    });

    testServer('caller attributes pass through to the button', (tester) async {
      tester.pumpComponent(
        _host(
          CommandSearch(
            attributes: const {'data-testid': 'palette-trigger'},
            onPressed: () {},
          ),
        ),
      );
      final trigger = (await tester.request(
        '/',
      )).document!.querySelector(_kTrigger);

      expect(trigger!.attributes['data-testid'], 'palette-trigger');
    });
  });

  group('CommandSearch seats', () {
    testServer('the locale placeholder is the hint by default', (
      tester,
    ) async {
      tester.pumpComponent(_host(CommandSearch(onPressed: () {})));
      final response = await tester.request('/');

      expect(
        response.document?.body?.text,
        contains(DefaultCouiLocalizations.instance.commandSearch),
      );
    });

    testServer('a stated hint and shortcut both render, hint first', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          CommandSearch(
            hint: 'Search docs',
            shortcut: const Kbd(keys: ['⌘K']),
            onPressed: () {},
          ),
        ),
      );
      final response = await tester.request('/');
      final text = response.document!.body!.text;

      expect(text, contains('Search docs'));
      expect(text, contains('⌘K'));
      expect(text.indexOf('Search docs'), lessThan(text.indexOf('⌘K')));
    });

    testServer('the hint seat takes the remaining width and truncates', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(CommandSearch(hint: 'Search docs', onPressed: () {})),
      );
      final response = await tester.request('/');
      final hint = response.document!
          .querySelectorAll('div')
          .firstWhere((e) => e.classes.contains('truncate'));

      expect(hint.classes, containsAll(['min-w-0', 'flex-1']));
      expect(hint.text, 'Search docs');
    });
  });

  group('CommandSearch size ladder', () {
    Future<String> rootStyle(
      ServerTester tester,
      CoreCommandSize size,
    ) async {
      tester.pumpComponent(
        _host(CommandSearch(size: size, onPressed: () {})),
      );
      return (await tester.request(
            '/',
          )).document?.querySelector(_kTrigger)?.attributes['style'] ??
          '';
    }

    testServer('heights go out as control-ladder variables', (tester) async {
      expect(
        await rootStyle(tester, CoreCommandSize.sm),
        contains('height: var(--coui-control-height-32)'),
      );
      expect(
        await rootStyle(tester, CoreCommandSize.md),
        contains('height: var(--coui-control-height-40)'),
      );
      expect(
        await rootStyle(tester, CoreCommandSize.lg),
        contains('height: var(--coui-control-height-48)'),
      );
    });

    testServer('insets are logical — start and end mirror with dir', (
      tester,
    ) async {
      final md = await rootStyle(tester, CoreCommandSize.md);

      expect(md, contains('padding-inline-start: var(--coui-space-12)'));
      expect(md, contains('padding-inline-end: var(--coui-space-10)'));
      expect(md, isNot(contains('padding-left')));
    });

    testServer('a caller height stays as stated', (tester) async {
      tester.pumpComponent(
        _host(
          CommandSearch(onPressed: () {}).withStyle(
            const CoreCommandSearchStyle(height: CoreSize.size36),
          ),
        ),
      );
      final style = (await tester.request(
        '/',
      )).document!.querySelector(_kTrigger)!.attributes['style']!;

      expect(style, contains('height: 2.25rem'));
      expect(style, isNot(contains('--coui-control-height')));
    });
  });

  group('CommandSearch face and ink', () {
    testServer('rests on surfaceContainer with no border', (tester) async {
      tester.pumpComponent(_host(CommandSearch(onPressed: () {})));
      final trigger = (await tester.request(
        '/',
      )).document!.querySelector(_kTrigger)!;

      expect(trigger.classes, contains('bg-surface-container'));
      expect(trigger.classes.any((c) => c.startsWith('border')), isFalse);
    });

    testServer('the hint reads onSurfaceVariant in the size row role', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(CommandSearch(hint: 'Search', onPressed: () {})),
      );
      final hint = (await tester.request('/')).document!
          .querySelectorAll('div')
          .firstWhere((e) => e.classes.contains('truncate'));

      expect(hint.classes, contains('text-on-surface-variant'));
      expect(hint.classes, contains('text-body-medium'));
    });

    testServer('disabled drops face and hint to the disabled pair', (
      tester,
    ) async {
      tester.pumpComponent(_host(const CommandSearch(hint: 'Search')));
      final response = await tester.request('/');
      final trigger = response.document!.querySelector(_kTrigger)!;
      final hint = response.document!
          .querySelectorAll('div')
          .firstWhere((e) => e.classes.contains('truncate'));

      expect(trigger.classes, contains('bg-disabled-container'));
      expect(hint.classes, contains('text-disabled-content'));
    });

    testServer('a project theme reaches every trigger', (tester) async {
      tester.pumpComponent(
        _host(
          Theme(
            data: ThemeData.coui.copyWith(
              coreComponentTheme: const CoreComponentTheme(
                commandSearch: CoreCommandSearchTheme(
                  style: CoreCommandSearchStyle(
                    backgroundColor: CoreColor.token(
                      CoreColors.surfaceContainerHigh,
                    ),
                  ),
                ),
              ),
            ),
            child: CommandSearch(onPressed: () {}),
          ),
        ),
      );
      final trigger = (await tester.request(
        '/',
      )).document!.querySelector(_kTrigger)!;

      expect(trigger.classes, contains('bg-surface-container-high'));
    });
  });

  group('CommandSearch box', () {
    testServer('the trigger is a block-level flex — display is stated once, '
        'inline, with no class competing with the Clickable inline-flex', (
      tester,
    ) async {
      tester.pumpComponent(_host(CommandSearch(onPressed: () {})));
      final trigger = (await tester.request(
        '/',
      )).document!.querySelector(_kTrigger)!;

      // Tailwind emits `inline-flex` after `flex`, so a `flex` class beside
      // the Clickable's `inline-flex` loses and the trigger turns
      // inline-level. The declaration that wins is the inline one.
      expect(trigger.classes, isNot(contains('flex')));
      expect(trigger.attributes['style'], contains('display: flex'));
    });
  });

  group('CommandSearch corner', () {
    const preset = [
      'rounded-tl-radius10',
      'rounded-tr-radius10',
      'rounded-bl-radius10',
      'rounded-br-radius10',
    ];

    /// The trigger and its wash overlay, as `class` / `style` attribute text.
    Future<
      ({
        Set<String> classes,
        String style,
        Set<String> washClasses,
        String washStyle,
      })
    >
    corner(
      ServerTester tester,
      Component trigger,
    ) async {
      tester.pumpComponent(_host(trigger));
      final document = (await tester.request('/')).document!;
      final root = document.querySelector(_kTrigger)!;
      final wash = document.querySelector('.co-command-search-wash')!;
      return (
        classes: root.classes.toSet(),
        style: root.attributes['style'] ?? '',
        washClasses: wash.classes.toSet(),
        washStyle: wash.attributes['style'] ?? '',
      );
    }

    const ring20 = CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    );

    testServer('the default corner travels as the size row preset classes, '
        'not inline', (tester) async {
      final box = await corner(tester, CommandSearch(onPressed: () {}));

      expect(box.classes, containsAll(preset));
    });

    testServer("the ring follows the trigger's corner by default", (
      tester,
    ) async {
      final box = await corner(tester, CommandSearch(onPressed: () {}));

      // The composed Clickable writes its radius inline, which outranks the
      // trigger's preset class — so the corner it is seeded with has to be
      // the trigger's, or the ring (and the box) would take the Clickable's
      // own default.
      expect(
        box.style,
        startsWith('border-radius: var(--coui-radius-10)'),
        reason: box.style,
      );
    });

    testServer('every size row corner reaches the ring', (tester) async {
      const corners = {
        CoreCommandSize.sm: 'radius-8',
        CoreCommandSize.md: 'radius-10',
        CoreCommandSize.lg: 'radius-12',
      };
      for (final MapEntry(key: size, value: radius) in corners.entries) {
        final box = await corner(
          tester,
          CommandSearch(size: size, onPressed: () {}),
        );

        expect(
          box.style,
          contains('border-radius: var(--coui-$radius)'),
          reason: '${size.name}: ${box.style}',
        );
      }
    });

    testServer('the wash takes the same corner as the box', (tester) async {
      final box = await corner(tester, CommandSearch(onPressed: () {}));

      expect(box.washClasses, containsAll(preset));
    });

    testServer('a stated corner goes inline and drops the preset classes, '
        'on the box and on the wash', (tester) async {
      final box = await corner(
        tester,
        CommandSearch(onPressed: () {}).withStyle(
          const CoreCommandSearchStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
          ),
        ),
      );

      expect(box.classes.any((c) => c.startsWith('rounded-')), isFalse);
      expect(box.style, contains('border-radius: var(--coui-radius-20)'));
      expect(box.washClasses.any((c) => c.startsWith('rounded-')), isFalse);
      expect(box.washStyle, contains('border-radius: var(--coui-radius-20)'));
    });

    testServer('a corner a caller states for the ring reaches the ring', (
      tester,
    ) async {
      final box = await corner(
        tester,
        CommandSearch(onPressed: () {}).withStyle(
          const CoreCommandSearchStyle(clickableStyle: ring20),
        ),
      );

      // The outline follows the border box, so the corner the ring is drawn
      // on is the one the element states. The wash rides the same corner so
      // its edge does not poke out of the face.
      expect(
        box.style,
        contains('border-radius: var(--coui-radius-20)'),
        reason: box.style,
      );
      expect(box.style, isNot(contains('--coui-radius-10')));
      expect(box.washStyle, contains('border-radius: var(--coui-radius-20)'));
    });

    testServer("the trigger's own corner outranks a ring corner — one "
        'border box on Web', (tester) async {
      final box = await corner(
        tester,
        CommandSearch(onPressed: () {}).withStyle(
          const CoreCommandSearchStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
            clickableStyle: ring20,
          ),
        ),
      );

      expect(box.style, contains('border-radius: var(--coui-radius-12)'));
      expect(box.style, isNot(contains('--coui-radius-20')));
    });
  });

  group('CommandSearch state layer', () {
    testServer('onSurface washes the overlay at 8 / 8 / 12', (tester) async {
      tester.pumpComponent(_host(CommandSearch(onPressed: () {})));
      final css = (await tester.request(
        '/',
      )).document!.querySelectorAll('style').map((e) => e.text).join();

      expect(
        RegExp(
          r':hover > \.co-command-search-wash\{background-color:'
          r'rgb\(var\(--coui-on-surface\) / 8%\);\}',
        ).hasMatch(css),
        isTrue,
        reason: css,
      );
      expect(
        RegExp(
          r':focus-visible > \.co-command-search-wash\{background-color:'
          r'rgb\(var\(--coui-on-surface\) / 8%\);\}',
        ).hasMatch(css),
        isTrue,
        reason: css,
      );
      expect(
        RegExp(
          r':active > \.co-command-search-wash\{background-color:'
          r'rgb\(var\(--coui-on-surface\) / 12%\);\}',
        ).hasMatch(css),
        isTrue,
        reason: css,
      );
    });

    testServer('a disabled trigger writes no wash rules', (tester) async {
      tester.pumpComponent(_host(const CommandSearch(hint: 'Search')));
      final css = (await tester.request(
        '/',
      )).document!.querySelectorAll('style').map((e) => e.text).join();

      expect(css, isNot(contains('co-command-search-wash{')));
    });
  });
}
