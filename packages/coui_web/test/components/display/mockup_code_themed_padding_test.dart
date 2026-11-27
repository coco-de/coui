/// Real composition regressions: the product's body inset must not stack
/// with the composed primitive's inherited inset. No observer is invoked.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' as server;

const _kInherited = CoreEdgeInsets.only(
  top: 32,
  right: 48,
  bottom: 64,
  left: 24,
);
const _kInheritedCss = <String, String>{
  'padding':
      'var(--coui-space-32) var(--coui-space-48) '
      'var(--coui-space-64) var(--coui-space-24)',
};
const _kPhysical = CoreEdgeInsets.only(top: 4, right: 8, bottom: 12, left: 22);
const _kPhysicalCss = <String, String>{
  'padding':
      'var(--coui-space-4) var(--coui-space-8) '
      'var(--coui-space-12) 1.375rem',
};
const _kThemeInset = CoreEdgeInsets.fromLTRB(4, 8, 16, 24);
const _kThemeCss = <String, String>{
  'padding':
      'var(--coui-space-8) var(--coui-space-16) '
      'var(--coui-space-24) var(--coui-space-4)',
};
const _kZeroCss = <String, String>{
  'padding':
      'var(--coui-space-0) var(--coui-space-0) '
      'var(--coui-space-0) var(--coui-space-0)',
};
const _kLines = [
  CoreCodeLine(text: 'alpha', prefix: '1'),
  CoreCodeLine(text: '', prefix: ''),
  CoreCodeLine(text: 'omega', tone: CoreCodeLineTone.error),
];

Map<String, String> _declarations(String style) => {
  for (final part in style.split(';'))
    if (part.contains(':'))
      part.substring(0, part.indexOf(':')).trim(): part
          .substring(part.indexOf(':') + 1)
          .trim(),
};
Map<String, String> _padding(Map<String, String> declarations) => {
  for (final entry in declarations.entries)
    if (entry.key == 'padding' || entry.key.startsWith('padding-'))
      entry.key: entry.value,
};

void main() {
  const cases =
      <
        ({
          String name,
          CoreEdgeInsets inherited,
          Map<String, String> inheritedCss,
          CoreEdgeInsets? themeInset,
          CoreEdgeInsets? instanceInset,
          Map<String, String> bodyCss,
          bool rtl,
        })
      >[
        (
          name: 'default product inset overrides an asymmetric outlined theme',
          inherited: _kInherited,
          inheritedCss: _kInheritedCss,
          themeInset: null,
          instanceInset: null,
          bodyCss: {
            'padding':
                'var(--coui-space-10) var(--coui-space-16) '
                'var(--coui-space-10) var(--coui-space-16)',
          },
          rtl: false,
        ),
        (
          name:
              'explicit asymmetric product inset overrides the outlined theme',
          inherited: _kInherited,
          inheritedCss: _kInheritedCss,
          themeInset: null,
          instanceInset: _kPhysical,
          bodyCss: _kPhysicalCss,
          rtl: false,
        ),
        (
          name:
              'the mockup-code theme owns the inset before the outlined theme',
          inherited: _kInherited,
          inheritedCss: _kInheritedCss,
          themeInset: _kThemeInset,
          instanceInset: null,
          bodyCss: _kThemeCss,
          rtl: false,
        ),
        (
          name: 'an instance inset replaces the mockup theme in an RTL host',
          inherited: _kInherited,
          inheritedCss: _kInheritedCss,
          themeInset: _kThemeInset,
          instanceInset: _kPhysical,
          bodyCss: _kPhysicalCss,
          rtl: true,
        ),
        (
          name:
              'zero product inset remains zero under a nonzero outlined theme',
          inherited: _kInherited,
          inheritedCss: _kInheritedCss,
          themeInset: _kThemeInset,
          instanceInset: CoreEdgeInsets.zero,
          bodyCss: _kZeroCss,
          rtl: false,
        ),
        (
          name:
              'directional product inset replaces directional outlined padding',
          inherited: CoreEdgeInsets.directional(
            top: 32,
            bottom: 64,
            start: 24,
            end: 48,
          ),
          inheritedCss: {
            'padding-block-start': 'var(--coui-space-32)',
            'padding-block-end': 'var(--coui-space-64)',
            'padding-inline-start': 'var(--coui-space-24)',
            'padding-inline-end': 'var(--coui-space-48)',
          },
          themeInset: null,
          instanceInset: CoreEdgeInsets.directional(
            top: 4,
            bottom: 12,
            start: 16,
            end: 8,
          ),
          bodyCss: {
            'padding-block-start': 'var(--coui-space-4)',
            'padding-block-end': 'var(--coui-space-12)',
            'padding-inline-start': 'var(--coui-space-16)',
            'padding-inline-end': 'var(--coui-space-8)',
          },
          rtl: true,
        ),
      ];

  for (final fixture in cases) {
    server.testServer(fixture.name, (tester) async {
      final theme = ThemeData.coui.copyWith(
        coreComponentTheme: CoreComponentTheme(
          outlinedContainer: CoreOutlinedContainerTheme(
            style: CoreOutlinedContainerStyle(
              padding: fixture.inherited,
              borderColor: CoreColor.transparent,
            ),
          ),
          mockupCode: CoreMockupCodeTheme(
            style: CoreMockupCodeStyle(padding: fixture.themeInset),
          ),
        ),
      );
      tester.pumpComponent(
        CoUIWeb(
          theme: theme,
          child: div(
            attributes: {'dir': fixture.rtl ? 'rtl' : 'ltr'},
            [
              MockupCode(
                id: 'code-owned',
                lines: _kLines,
                mockupCodeStyle: CoreMockupCodeStyle(
                  padding: fixture.instanceInset,
                ),
              ),
              const OutlinedContainer(
                id: 'bare-outlined-control',
                child: div([]),
              ),
            ],
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final bare = document.querySelector('#bare-outlined-control')!;
      // Fixture health: a bare primitive must still inherit the exact T.
      // The fix belongs to MockupCode, never to the generic primitive/theme.
      expect(
        _padding(_declarations(bare.attributes['style'] ?? '')),
        fixture.inheritedCss,
      );
      final root = document.querySelector('#code-owned')!;
      printOnFailure(root.outerHtml);
      printOnFailure(bare.outerHtml);
      expect(root.children, hasLength(1));
      final frame = root.children.single;
      expect(frame.children, hasLength(1));
      final body = frame.children.single;
      // Exact declared root -> composed frame -> content body, no text/class
      // query chooses an owner. This is ordinary product rendering, not an
      // observation-source grant or a call to either style resolver.
      expect(
        _padding(_declarations(body.attributes['style'] ?? '')),
        fixture.bodyCss,
      );
      expect(body.children, hasLength(3));
      expect(body.children.map((row) => row.children.length), [2, 2, 1]);
      expect(body.children[0].children[0].text, '1');
      expect(body.children[0].children[1].text, 'alpha');
      expect(body.children[1].children[0].text, '');
      expect(body.children[1].children[1].text, '');
      expect(body.children[2].children.single.text, 'omega');
      expect(
        body.children[2].children.single.attributes['class'],
        contains('text-on-error-container'),
      );
      // The last row's distinct bottom spacing must not be folded into P.
      expect(
        _declarations(
          body.children.last.attributes['style'] ?? '',
        )['padding-bottom'],
        'var(--coui-space-4)',
      );
      expect(_padding(_declarations(frame.attributes['style'] ?? '')), {
        'padding': 'var(--coui-space-0)',
      }, reason: 'MOCKUP_CODE_FRAME_MUST_NOT_ADD_INHERITED_T');
    });
  }

  for (final clipping in [CoreClipBehavior.none, CoreClipBehavior.antiAlias]) {
    server.testServer(
      'inherited padding leaves rounded border and line chrome intact '
      '($clipping)',
      (tester) async {
        final base = CoreOutlinedContainerStyle(
          padding: CoreEdgeInsets.zero,
          borderWidth: 2,
          preserveTransparentBorder: true,
          clipBehavior: clipping,
        );
        ThemeData themed(CoreOutlinedContainerStyle outlined) =>
            ThemeData.coui.copyWith(
              coreComponentTheme: CoreComponentTheme(
                outlinedContainer: CoreOutlinedContainerTheme(style: outlined),
              ),
            );
        MockupCode code(String id) => MockupCode(
          id: id,
          lines: _kLines,
          mockupCodeStyle: const CoreMockupCodeStyle(
            padding: _kPhysical,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
          ),
        );
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: div([
              Theme(data: themed(base), child: code('control')),
              Theme(
                data: themed(base.copyWith(padding: _kInherited)),
                child: code('themed'),
              ),
            ]),
          ),
        );
        final document = (await tester.request('/')).document!;
        final controlRoot = document.querySelector('#control')!;
        final themedRoot = document.querySelector('#themed')!;
        printOnFailure(controlRoot.outerHtml);
        printOnFailure(themedRoot.outerHtml);
        expect(controlRoot.children, hasLength(1));
        expect(themedRoot.children, hasLength(1));
        final controlFrame = controlRoot.children.single;
        final frame = themedRoot.children.single;
        final controlCss = _declarations(
          controlFrame.attributes['style'] ?? '',
        );
        final css = _declarations(frame.attributes['style'] ?? '');
        expect(
          css['border-radius'],
          'var(--coui-radius-16) var(--coui-radius-16) '
          'var(--coui-radius-16) var(--coui-radius-16)',
        );
        expect(css['border-width'], isNotNull);
        expect(frame.attributes['class'], controlFrame.attributes['class']);
        expect(frame.children, hasLength(1));
        expect(controlFrame.children, hasLength(1));
        expect(
          frame.children.single.outerHtml,
          controlFrame.children.single.outerHtml,
        );
        expect(
          _padding(
            _declarations(frame.children.single.attributes['style'] ?? ''),
          ),
          _kPhysicalCss,
        );
        expect(
          css,
          controlCss,
          reason: 'MOCKUP_CODE_FRAME_MUST_NOT_ADD_INHERITED_T_WITH_CHROME',
        );
      },
    );
  }

  server.testServer(
    'an empty line roster retains only the product body inset',
    (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              outlinedContainer: CoreOutlinedContainerTheme(
                style: CoreOutlinedContainerStyle(padding: _kInherited),
              ),
            ),
          ),
          child: const MockupCode(id: 'empty-code', lines: []),
        ),
      );
      final document = (await tester.request('/')).document!;
      final root = document.querySelector('#empty-code')!;
      printOnFailure(root.outerHtml);
      expect(root.children, hasLength(1));
      final frame = root.children.single;
      expect(frame.children, hasLength(1));
      final body = frame.children.single;
      expect(body.children, isEmpty);
      expect(_padding(_declarations(body.attributes['style'] ?? '')), {
        'padding':
            'var(--coui-space-10) var(--coui-space-16) '
            'var(--coui-space-10) var(--coui-space-16)',
      });
      expect(_padding(_declarations(frame.attributes['style'] ?? '')), {
        'padding': 'var(--coui-space-0)',
      }, reason: 'MOCKUP_CODE_EMPTY_FRAME_MUST_NOT_ADD_INHERITED_T');
    },
  );
}
