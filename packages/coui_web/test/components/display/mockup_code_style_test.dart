// The values under test are the design numbers (10 / 16 inset, 28 gutter) —
// naming each one would hide what the assertion is about.

/// Emitted-value tests for the `MockupCode` product defaults on Web: the
/// vertical 10 / horizontal 16 inset, the `codeSm` text and gutter roles,
/// and the 28px gutter.
///
/// The inset is the claim that needs the markup. The existing content body
/// owns it; the composed frame explicitly suppresses inherited padding.
/// These read the emitted inline CSS and the real SSR document.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' as server;

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

ResolvedMockupCode _resolve(
  ComponentTester tester, {
  CoreMockupCodeStyle? style,
}) {
  late ResolvedMockupCode resolved;
  pumpWithTheme(
    tester,
    _ContextCapture(
      (context) =>
          resolved = resolveMockupCode(context, mockupCodeStyle: style),
    ),
  );
  return resolved;
}

/// Inline CSS rendered to one string, the declarations the browser receives.
String _css(WebElementChrome chrome) => (chrome.inlineStyles?.properties ?? {})
    .entries
    .map((e) => '${e.key}: ${e.value}')
    .join('; ');

Map<String, String> _declarations(String style) => {
  for (final part in style.split(';'))
    if (part.contains(':'))
      part.substring(0, part.indexOf(':')).trim(): part
          .substring(part.indexOf(':') + 1)
          .trim(),
};

void main() {
  group('MockupCode resolver — inset', () {
    testComponents('the default inset is a four-side padding, 10 / 16', (
      tester,
    ) async {
      final body = _resolve(tester).body.inlineStyles!.properties;
      expect(
        body['padding'],
        'var(--coui-space-10) var(--coui-space-16) '
        'var(--coui-space-10) var(--coui-space-16)',
      );
    });

    testComponents('the frame explicitly suppresses inherited padding', (
      tester,
    ) async {
      expect(_resolve(tester).frameStyle.padding, CoreEdgeInsets.zero);
    });

    testComponents('a caller inset reaches the body on every side', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        style: const CoreMockupCodeStyle(
          padding: CoreEdgeInsets.only(
            top: 4,
            right: 8,
            bottom: 12,
            left: 22,
          ),
        ),
      );
      expect(
        resolved.body.inlineStyles!.properties['padding'],
        'var(--coui-space-4) var(--coui-space-8) '
        'var(--coui-space-12) 1.375rem',
      );
      expect(resolved.frameStyle.padding, CoreEdgeInsets.zero);
    });

    testComponents('a directional inset becomes logical longhands', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        style: const CoreMockupCodeStyle(
          padding: CoreEdgeInsets.directional(
            top: 10,
            bottom: 10,
            start: 16,
            end: 8,
          ),
        ),
      );
      final body = resolved.body.inlineStyles!.properties;
      expect(body, isNot(contains('padding')));
      expect(body['padding-inline-start'], 'var(--coui-space-16)');
      expect(body['padding-inline-end'], 'var(--coui-space-8)');
      expect(body['padding-block-start'], 'var(--coui-space-10)');
      expect(body['padding-block-end'], 'var(--coui-space-10)');
    });
  });

  group('MockupCode resolver — roles and gutter', () {
    testComponents('the gutter is 1.75rem (28px) wide', (tester) async {
      expect(_css(_resolve(tester).prefix), contains('width: 1.75rem'));
    });

    testComponents('text and gutter carry the code-sm role class', (
      tester,
    ) async {
      final resolved = _resolve(tester);
      expect(resolved.text.className.split(' '), contains('text-code-sm'));
      expect(resolved.prefix.className.split(' '), contains('text-code-sm'));
      expect(resolved.text.className, isNot(contains('body-small')));
      expect(resolved.prefix.className, isNot(contains('body-small')));
    });

    testComponents('the colour slots keep their token classes', (
      tester,
    ) async {
      final resolved = _resolve(tester);
      expect(resolved.text.className.split(' '), contains('text-on-surface'));
      expect(
        resolved.prefix.className.split(' '),
        contains('text-on-surface-variant'),
      );
    });
  });

  group('MockupCode resolver — the face', () {
    testComponents('the frame is handed the surfaceContainerLow token', (
      tester,
    ) async {
      expect(
        _resolve(tester).frameStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
    });

    // A token face stays a class, so the browser re-resolves it when the
    // theme flips — the colour is not baked into the markup.
    testComponents('the composed frame emits the face as a token class', (
      tester,
    ) async {
      late ResolvedOutlinedContainer frame;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => frame = resolveOutlinedContainer(
            context: context,
            containerStyle: resolveMockupCode(context).frameStyle,
          ),
        ),
      );
      final classes = frame.root.className.split(' ');
      expect(classes, contains('bg-surface-container-low'));
      expect(classes, isNot(contains('bg-surface-container')));
      expect(_css(frame.root), isNot(contains('background-color')));
    });

    testComponents('the shared mockup theme fill replaces the default face', (
      tester,
    ) async {
      late ResolvedMockupCode resolved;
      tester.pumpComponent(
        Theme(
          data: ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              mockup: CoreMockupTheme(
                style: CoreMockupStyle(
                  backgroundColor: CoreColor.token(
                    CoreColors.surfaceContainerHigh,
                  ),
                ),
              ),
            ),
          ),
          child: _ContextCapture(
            (context) => resolved = resolveMockupCode(context),
          ),
        ),
      );
      expect(
        resolved.frameStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
    });

    testComponents('a stated surfaceContainer still wins over the default', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        style: const CoreMockupCodeStyle(
          backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        ),
      );
      expect(
        resolved.frameStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
    });
  });

  group('MockupCode SSR — the inset is in the document', () {
    server.testServer('the content wrapper carries the 10 / 16 padding, the '
        'frame adds no padding', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: MockupCode.fromString('a\nb'),
        ),
      );
      final response = await tester.request('/');
      final document = response.document!;

      // The element that holds the rows is the one that pads them.
      final rowText = document
          .querySelectorAll('span')
          .where((el) => el.text.trim() == 'a')
          .single;
      final row = rowText.parent!;
      final body = row.parent!;
      final bodyStyle = _declarations(body.attributes['style'] ?? '');
      expect(
        bodyStyle['padding'],
        'var(--coui-space-10) var(--coui-space-16) '
        'var(--coui-space-10) var(--coui-space-16)',
      );

      // The frame is the composed primitive. It must suppress inherited
      // padding while the body retains the complete four-side allocation.
      final frame = body.parent!;
      expect(
        _declarations(frame.attributes['style'] ?? '')['padding'],
        'var(--coui-space-0)',
      );

      // The face the page paints: the lighter container step, as a token
      // class the browser re-resolves per theme.
      final frameClasses = (frame.attributes['class'] ?? '').split(' ');
      expect(frameClasses, contains('bg-surface-container-low'));
      expect(frameClasses, isNot(contains('bg-surface-container')));

      // Both rows live in the one padded wrapper.
      expect(body.children, hasLength(2));

      // The gutter box is 28px, on the size the browser can scale.
      final gutter = document
          .querySelectorAll('span')
          .where((el) => el.text.trim() == '1')
          .single;
      expect(gutter.attributes['style'], contains('width: 1.75rem'));
    });
  });
  group('MockupCode resolver — line tone', () {
    const tokenClass = {
      CoreCodeLineTone.muted: 'text-on-surface-variant',
      CoreCodeLineTone.link: 'text-link',
      CoreCodeLineTone.success: 'text-on-success-container',
      CoreCodeLineTone.warning: 'text-on-warning-container',
      CoreCodeLineTone.error: 'text-on-error-container',
    };

    testComponents('a neutral line is the code text chrome, unchanged', (
      tester,
    ) async {
      final resolved = _resolve(tester);
      final neutral = resolved.toneText[CoreCodeLineTone.neutral.index];
      expect(neutral.className, resolved.text.className);
      expect(neutral.className.split(' '), contains('text-on-surface'));
      expect(neutral.inlineStyles, isNull);
    });

    for (final entry in tokenClass.entries) {
      testComponents('${entry.key.name} is a token class, nothing inline', (
        tester,
      ) async {
        final chrome = _resolve(tester).toneText[entry.key.index];
        final classes = chrome.className.split(' ');
        expect(classes, contains(entry.value));
        // The colour is the only thing a tone swaps: the role class and the
        // no-wrap rule stay, and the neutral colour class is gone.
        expect(classes, contains('text-code-sm'));
        expect(classes, contains('whitespace-nowrap'));
        expect(classes, isNot(contains('text-on-surface')));
        expect(chrome.inlineStyles, isNull);
      });
    }

    testComponents('a raw tone override goes inline, with no tone class', (
      tester,
    ) async {
      final chrome = _resolve(
        tester,
        style: const CoreMockupCodeStyle(
          errorToneColor: CoreColor(0xFFAA3355),
        ),
      ).toneText[CoreCodeLineTone.error.index];
      final classes = chrome.className.split(' ');
      expect(classes, isNot(contains('text-on-error-container')));
      expect(classes, isNot(contains('text-on-surface')));
      expect(classes, contains('text-code-sm'));
      expect(_css(chrome), contains('color:'));
    });

    testComponents('a token tone override stays a class', (tester) async {
      final chrome = _resolve(
        tester,
        style: const CoreMockupCodeStyle(
          successToneColor: CoreColor.token(CoreColors.primary),
        ),
      ).toneText[CoreCodeLineTone.success.index];
      expect(chrome.className.split(' '), contains('text-primary'));
      expect(chrome.inlineStyles, isNull);
    });

    testComponents('a recoloured code text recolours neutral only', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        style: const CoreMockupCodeStyle(
          textStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      );
      expect(
        resolved.toneText[CoreCodeLineTone.neutral.index].className.split(' '),
        contains('text-tertiary'),
      );
      expect(
        resolved.toneText[CoreCodeLineTone.link.index].className.split(' '),
        contains('text-link'),
      );
    });

    testComponents('every tone has an entry', (tester) async {
      expect(
        _resolve(tester).toneText,
        hasLength(CoreCodeLineTone.values.length),
      );
    });
  });

  group('MockupCode SSR — line tone', () {
    server.testServer('each line carries its tone class in the document, and '
        'the gutter keeps its own', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: MockupCode.fromList(const [
            CoreCodeLine(text: 'plain', prefix: '1'),
            CoreCodeLine(
              text: 'listening',
              prefix: '2',
              tone: CoreCodeLineTone.link,
            ),
            CoreCodeLine(
              text: 'failed',
              prefix: '3',
              tone: CoreCodeLineTone.error,
            ),
          ]),
        ),
      );
      final document = (await tester.request('/')).document!;

      List<String> classesOf(String text) =>
          (document
                      .querySelectorAll('span')
                      .where((el) => el.text.trim() == text)
                      .single
                      .attributes['class'] ??
                  '')
              .split(' ');

      expect(classesOf('plain'), contains('text-on-surface'));
      expect(classesOf('listening'), contains('text-link'));
      expect(classesOf('listening'), isNot(contains('text-on-surface')));
      expect(classesOf('failed'), contains('text-on-error-container'));
      // The gutter is not a tone: same colour on every row.
      for (final prefix in const ['1', '2', '3']) {
        expect(classesOf(prefix), contains('text-on-surface-variant'));
      }
    });
  });
}
