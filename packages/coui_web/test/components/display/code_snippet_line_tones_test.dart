import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart' as jaspr show Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _code = 'final a = 1;\nfinal b = 2;\nfinal c = 3;\nfinal d = 4;';

/// The DOM children of [element] — the nearest element nodes under it, past
/// the components (`div`, `span`) that only wrap one.
List<Element> _domChildren(Element element) {
  final out = <Element>[];
  void visit(Element child) {
    if (child.component is DomComponent) {
      out.add(child);
    } else {
      child.visitChildren(visit);
    }
  }

  element.visitChildren(visit);
  return out;
}

DomComponent _dom(Element element) => element.component as DomComponent;

/// The `<code>` element.
Element _codeElement() => find.tag('code').evaluate().single;

/// The layer the bands sit in, if the snippet draws one.
Element? _bandLayer() {
  Element? found;
  void visit(Element element) {
    if (found != null) return;
    final component = element.component;
    if (component is DomComponent &&
        (component.classes?.split(' ').contains('pointer-events-none') ??
            false)) {
      found = element;
      return;
    }
    element.visitChildren(visit);
  }

  _codeElement().visitChildren(visit);
  return found;
}

/// The rows of the band layer.
List<DomComponent> _rows() => _domChildren(_bandLayer()!).map(_dom).toList();

/// The text under [element].
String _text(Element element) {
  final out = StringBuffer();
  void visit(Element child) {
    if (child.component case jaspr.Text(:final text)) out.write(text);
    child.visitChildren(visit);
  }

  visit(element);
  return out.toString();
}

void _pump(
  ComponentTester tester, {
  Map<int, CoreCodeLineTone> lineTones = const {},
  bool showLineNumbers = true,
  CoreCodeSnippetStyle? style,
  CouiLocalizations? localizations,
}) {
  final Component snippet = CodeSnippet(
    code: _code,
    mode: 'dart',
    showLineNumbers: showLineNumbers,
    lineTones: lineTones,
    showCopyButton: false,
    codeSnippetStyle: style,
  );
  pumpWithTheme(
    tester,
    localizations == null
        ? snippet
        : CouiLocalizationsScope(localizations: localizations, child: snippet),
  );
}

void main() {
  group('Web CodeSnippet lineTones', () {
    testComponents('no tone emits the markup the snippet always had', (
      tester,
    ) async {
      expect(const CodeSnippet(code: _code, mode: 'dart').lineTones, isEmpty);
      _pump(tester);

      expect(_bandLayer(), isNull);
      // The gutter-and-code row sits directly under `<code>`, as it always
      // did.
      expect(_domChildren(_codeElement()).map((e) => _dom(e).classes), [
        'flex',
      ]);
    });

    testComponents('a row per line up to the last band, coloured by tone', (
      tester,
    ) async {
      _pump(
        tester,
        lineTones: const {
          2: CoreCodeLineTone.success,
          3: CoreCodeLineTone.warning,
          4: CoreCodeLineTone.error,
        },
      );

      final rows = _rows();
      expect(rows, hasLength(4));
      expect(rows.map((r) => r.classes ?? ''), [
        '',
        'bg-success-container',
        'bg-warning-container',
        'bg-error-container',
      ]);
      for (final row in rows) {
        expect(row.styles?.properties['height'], '1lh');
      }
    });

    testComponents('rows stop at the last band', (tester) async {
      _pump(tester, lineTones: const {2: CoreCodeLineTone.error});

      expect(_rows(), hasLength(2));
    });

    testComponents('the other tones and lines outside the code draw nothing', (
      tester,
    ) async {
      _pump(
        tester,
        lineTones: const {
          1: CoreCodeLineTone.neutral,
          2: CoreCodeLineTone.muted,
          3: CoreCodeLineTone.link,
          9: CoreCodeLineTone.error,
          0: CoreCodeLineTone.error,
        },
      );

      expect(_bandLayer(), isNull);
    });

    testComponents('the layer runs under the padding on both sides', (
      tester,
    ) async {
      _pump(tester, lineTones: const {1: CoreCodeLineTone.success});

      final layer = _dom(_bandLayer()!);
      expect(layer.classes, 'absolute pointer-events-none');
      final inset = spaceCss(CoreCodeSnippetStyle.defaultPadding.left);
      expect(layer.styles?.properties, {
        'top': '0',
        'left': 'calc(-1 * $inset)',
        'right': 'calc(-1 * $inset)',
      });
      // At least as wide as the scroll area, as wide as its longest line.
      final host = _domChildren(_codeElement()).single;
      expect(_dom(host).classes, 'relative');
      expect(_dom(host).styles?.properties, {
        'min-width': '100%',
        'width': 'max-content',
      });
      // The layer first, then the code over it — which keeps its row.
      final [layerElement, content] = _domChildren(host);
      expect(layerElement, same(_bandLayer()));
      expect(_dom(content).classes, 'relative');
      expect(_domChildren(content).map((e) => _dom(e).classes), ['flex']);
    });

    testComponents('without the gutter the layer is the same', (tester) async {
      _pump(
        tester,
        showLineNumbers: false,
        lineTones: const {1: CoreCodeLineTone.success},
      );

      expect(_rows().single.classes, 'bg-success-container');
    });

    testComponents('each stated colour reaches its own tone', (tester) async {
      _pump(
        tester,
        lineTones: const {
          1: CoreCodeLineTone.success,
          2: CoreCodeLineTone.warning,
          3: CoreCodeLineTone.error,
        },
        style: const CoreCodeSnippetStyle(
          successLineColor: CoreColor.token(CoreColors.tertiaryContainer),
          warningLineColor: CoreColor.token(CoreColors.primaryContainer),
          errorLineColor: CoreColor.fromARGB(64, 255, 0, 0),
        ),
      );

      final rows = _rows();
      expect(rows[0].classes, 'bg-tertiary-container');
      expect(rows[1].classes, 'bg-primary-container');
      // A raw colour has no class — it goes inline.
      expect(rows[2].classes ?? '', '');
      expect(
        rows[2].styles?.properties['background-color'],
        const CoreColor.fromARGB(64, 255, 0, 0).toValue(),
      );
    });

    testComponents('each band says its tone in words', (tester) async {
      _pump(
        tester,
        lineTones: const {
          2: CoreCodeLineTone.success,
          3: CoreCodeLineTone.warning,
          4: CoreCodeLineTone.error,
        },
      );

      final rows = _domChildren(_bandLayer()!);
      expect(rows.map(_text), [
        '',
        'Line 2: success',
        'Line 3: warning',
        'Line 4: error',
      ]);
      final label = _dom(_domChildren(rows[1]).single);
      expect(label.tag, 'span');
      expect(label.classes, 'sr-only');
    });

    testComponents('the words follow the active locale', (tester) async {
      _pump(
        tester,
        lineTones: const {2: CoreCodeLineTone.error},
        localizations: KoCouiLocalizations.instance,
      );

      final row = _domChildren(_bandLayer()!).last;
      expect(
        _text(row),
        KoCouiLocalizations.instance.codeSnippetErrorLineLabel(2),
      );
      expect(_text(row), isNot('Line 2: error'));
    });
  });
}
