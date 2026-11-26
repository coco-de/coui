// #6470 — DescriptionCard redesign, read back from the server-rendered
// markup (the same tree the browser receives).
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show ServerTester, testServer;

const List<DescriptionRow> _rows = [
  DescriptionRow(label: '요금제', value: 'Pro'),
  DescriptionRow(label: '좌석', value: '10석 중 5석'),
  DescriptionRow(label: '갱신일', value: '2027년 6월'),
];

const List<CoreDescriptionCardSize> _sizes = CoreDescriptionCardSize.values;
const _padding = [12, 14, 16, 18, 20];
const _radius = [12, 14, 16, 16, 16];
const _sectionGap = [8, 8, 10, 10, 12];
const _rowInset = [6, 6, 8, 8, 10];
const _iconRem = ['1.0', '1.0', '1.125', '1.25', '1.25'];

Future<String> _card(
  ServerTester tester, {
  CoreDescriptionCardSize size = .md,
  CoreDescriptionCardVariant variant = .outlined,
}) async {
  tester.pumpComponent(
    CoUIWeb(
      theme: .coui,
      child: DescriptionCard(
        title: '구독',
        titleLeading: const Icon(LucideIcons.creditCard),
        size: size,
        variant: variant,
        rows: _rows,
      ),
    ),
  );
  final response = await tester.request('/');
  return response.document!.querySelector('.coui-surface')!.outerHtml;
}

String _inset(int v, int h) =>
    'padding: var(--coui-space-$v) var(--coui-space-$h) '
    'var(--coui-space-$v) var(--coui-space-$h)';

void main() {
  for (var i = 0; i < _sizes.length; i += 1) {
    final size = _sizes[i];
    testServer('${size.name}: padding, corner, section gap, rows, icon', (
      tester,
    ) async {
      final html = await _card(tester, size: size);
      final r = 'var(--coui-radius-${_radius[i]})';
      expect(html, contains('border-radius: $r $r $r $r'));
      expect(
        html,
        contains('padding: calc(var(--coui-space-${_padding[i]}) +'),
      );
      expect(
        html,
        contains('flex-basis: var(--coui-space-${_sectionGap[i]})'),
      );
      // Rows touch (gap 0); every row carries the vertical inset.
      expect(html, contains('flex flex-col gap-space0'));
      expect(
        _inset(_rowInset[i], 0).allMatches(html).length,
        _rows.length,
      );
      // Title leading icon — per-size glyph, on-surface-variant.
      expect(
        html,
        contains(
          '<iconify-icon class="text-on-surface-variant" '
          'style="width: ${_iconRem[i]}rem; height: ${_iconRem[i]}rem; '
          'font-size: ${_iconRem[i]}rem"',
        ),
      );
      // Title ↔ icon gap is 8 at every size.
      expect(html, contains('flex-basis: var(--coui-space-8)'));
    });
  }

  testServer('divider under every row but the last, plus the title rule', (
    tester,
  ) async {
    final html = await _card(tester);
    final rule = RegExp('bg-outline-variant" style="height: ');
    expect(rule.allMatches(html).length, 1 + _rows.length - 1);
    // Nothing follows the last row's value but the closing tags.
    final last = html.indexOf('2027년 6월');
    expect(rule.allMatches(html.substring(last)), isEmpty);
  });

  testServer('title SemiBold, value right-aligned, row centred', (
    tester,
  ) async {
    final html = await _card(tester);
    expect(html, contains('text-label-xl font-semibold text-on-surface'));
    expect(
      RegExp('text-label-large text-on-surface text-end').allMatches(html),
      hasLength(_rows.length),
    );
    expect(html, contains('<div class="flex items-center" style="padding'));
  });

  testServer('ghost: no fill, no border, no left / right inset', (
    tester,
  ) async {
    final html = await _card(tester, variant: .ghost);
    expect(html, contains(_inset(16, 0)));
    expect(html, isNot(contains('bg-surface')));
    expect(html, isNot(contains('border-outline-variant')));
  });

  testServer('filled: surface-container face, no border colour', (
    tester,
  ) async {
    final html = await _card(tester, variant: .filled);
    expect(html, contains('bg-surface-container'));
    expect(html, isNot(contains('border-outline-variant')));
  });

  Future<String> page(
    ServerTester tester, {
    bool? enabled,
    void Function()? onTap,
    Component? bottomAction,
  }) async {
    tester.pumpComponent(
      CoUIWeb(
        theme: .coui,
        child: DescriptionCard(
          title: '구독',
          titleLeading: const Icon(LucideIcons.creditCard),
          rows: _rows,
          onTap: onTap,
          enabled: enabled,
          bottomAction: bottomAction,
        ),
      ),
    );
    final response = await tester.request('/');
    return response.document!.body!.innerHtml;
  }

  testServer('disabled: content at opacity/disabled, box at full, no press', (
    tester,
  ) async {
    final html = await page(
      tester,
      enabled: false,
      onTap: () {},
      bottomAction: const Text('요금제 관리'),
    );
    // The content column (title + rows) dims; nothing else does.
    const dim = 'opacity: ${CoreOpacity.disabled}';
    expect(RegExp(dim).allMatches(html), hasLength(1));
    final content = html.indexOf(dim);
    expect(html.indexOf('구독'), greaterThan(content));
    expect(html.indexOf('2027년 6월'), greaterThan(content));
    // The bottom action region sits inside the dimmed column too: it
    // comes after the dimmed column opens, and the column has not closed
    // before it (the rows' closing `</div>`s are followed by the rule and
    // the action, still inside).
    final action = html.indexOf('요금제 관리');
    expect(action, greaterThan(content));
    final dimmed = RegExp(
      '<div class="flex flex-col" style="$dim">',
    ).firstMatch(html)!;
    final inner = html.substring(dimmed.start);
    expect(_closingIndex(inner), greaterThan(inner.indexOf('요금제 관리')));
    // The surface keeps its fill and border, undimmed.
    final surface = RegExp('<div class="coui-surface[^>]*>').firstMatch(html)!;
    expect(surface[0], contains('bg-surface border-outline-variant'));
    expect(surface[0], isNot(contains('opacity')));
    // The Clickable does not dim the card a second time.
    expect(html, isNot(contains('opacity: ${CoreOpacity.opacity50}')));
    // Announced disabled and out of the tab order.
    expect(html, contains('aria-disabled="true"'));
    expect(html, contains('cursor-not-allowed'));
    expect(html, isNot(contains('tabindex="0"')));
  });

  testServer('enabled with a tap target: not dimmed, focusable', (
    tester,
  ) async {
    final html = await page(tester, onTap: () {});
    expect(html, isNot(contains('opacity: ${CoreOpacity.disabled}')));
    expect(html, contains('tabindex="0"'));
    expect(html, isNot(contains('aria-disabled')));
  });

  testServer('a plain card (no tap target) never dims', (tester) async {
    final html = await page(
      tester,
      enabled: false,
      bottomAction: const Text('요금제 관리'),
    );
    expect(html, isNot(contains('opacity: ${CoreOpacity.disabled}')));
    expect(html, isNot(contains('aria-disabled')));
  });
}

/// Index of the `</div>` that closes the `<div>` [html] starts with.
int _closingIndex(String html) {
  final tag = RegExp(r'<div\b|</div>');
  var depth = 0;
  for (final m in tag.allMatches(html)) {
    depth += m[0] == '</div>' ? -1 : 1;
    if (depth == 0) return m.start;
  }
  return -1;
}
