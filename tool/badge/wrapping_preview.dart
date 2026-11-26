/// Run from the repository root:
/// dart run tool/badge/wrapping_preview.dart
/// Serve .dart_tool/badge-wrapping-preview and open index.html in Ego Lite.
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart';

import '../parity/src/web/local_icons.dart';
import '../parity/src/web/offline_tailwind_harness.dart';
import '../parity/src/web/ssr_render.dart';

const _kLabels = {
  'en': 'Available for a conversation with a new partner',
  'ko': '새로운 대화 상대와 함께 이야기할 수 있어요',
  'ja': '新しい会話のパートナーとお話しできます',
  'zh': '可以与新的聊天伙伴一起开始对话',
  'de': 'Bereit für ein Gespräch mit einem neuen Partner',
  'fr': 'Disponible pour discuter avec un nouveau partenaire',
  'es': 'Disponible para conversar con una nueva persona',
  'pt': 'Disponível para conversar com uma nova pessoa',
  'ru': 'Можно начать разговор с новым собеседником',
  'ar': 'متاح للمحادثة مع شريك جديد في الدردشة',
  'hi': 'नए साथी के साथ बातचीत शुरू करने के लिए उपलब्ध',
  'unbroken': 'Donaudampfschifffahrtsgesellschaftskapitän',
};

Future<void> main() async {
  final output = Directory('.dart_tool/badge-wrapping-preview')
    ..createSync(recursive: true);
  final body = await renderComponentBodyHtml(
    Theme.defaults(
      child: div([
        const h1([Component.text('Badge wrapping: bounded, natural, RTL')]),
        const p([
          Component.text(
            'Narrow cases use 160px bounds. The 2x pages use a 32px root '
            'font (rem scaling). These are illustrative translations, '
            'not BottariFX copy.',
          ),
        ]),
        for (final direction in ['ltr', 'rtl'])
          div(
            [
              h2([Component.text(direction)]),
              div([
                for (final label in _kLabels.entries)
                  div([
                    p([Component.text(label.key)]),
                    div(
                      [
                        Badge(
                          showDot: true,
                          leading: const Icon(LucideIcons.check),
                          trailing: const Icon(LucideIcons.chevronRight),
                          child: Text(label.value),
                        ),
                      ],
                      classes: 'bounded',
                      attributes: {'data-case': '${label.key}-$direction'},
                    ),
                  ]),
              ], classes: 'grid'),
            ],
            attributes: {'dir': direction},
          ),
        const h2([Component.text('Long count: one line, bounded width')]),
        for (final direction in ['ltr', 'rtl'])
          div(
            [
              const Badge(
                form: .count,
                child: Text('123456789012345678901234567890'),
              ),
            ],
            classes: 'bounded',
            attributes: {
              'dir': direction,
              'data-case': 'long-count-$direction',
            },
          ),
        const h2([
          Component.text(
            'Actual phone-auth title: 280px, primary/sm, no icons',
          ),
        ]),
        for (final direction in ['ltr', 'rtl'])
          for (final label in ['Проверка телефона', 'التحقق من الهاتف'])
            div(
              [
                Badge(
                  tone: CoreBadgeTone.primary,
                  size: CoreComponentSize.sm,
                  child: Text(label),
                ),
              ],
              classes: 'phone-auth',
              attributes: {
                'dir': direction,
                'data-case': 'phone-auth-$label-$direction',
              },
            ),
        for (final direction in ['ltr', 'rtl'])
          for (final label in [
            'Номер телефона подтверждён',
            'تم تأكيد رقم الهاتف',
          ])
            div(
              [
                Badge(
                  tone: CoreBadgeTone.success,
                  leading: const Icon(LucideIcons.check),
                  child: Text(label),
                ),
              ],
              classes: 'completion',
              attributes: {
                'dir': direction,
                'data-case': 'completion-$label-$direction',
              },
            ),
        const h2([
          Component.text(
            'Short text / count / dot / icons at natural width',
          ),
        ]),
        for (final variant in CoreBadgeVariant.values)
          div([
            Badge(variant: variant, child: const Text('Tag')),
            Badge(variant: variant, form: .count, child: const Text('12')),
            Badge(variant: variant, form: .dot),
            Badge(
              variant: variant,
              leading: const Icon(LucideIcons.check),
              child: const Text('Done'),
            ),
          ], classes: 'natural'),
        const h2([Component.text('Unbounded horizontal layout')]),
        div([
          div([
            Badge(child: Text(_kLabels['en']!)),
          ], classes: 'unbounded'),
        ], classes: 'scroll'),
        const pre([
          Component.text('Waiting for layout measurements…'),
        ], id: 'result'),
      ]),
    ),
  );
  final tailwind = loadVendoredTailwindScript();
  final icons = buildLocalIconifyHeadHtml();
  for (final theme in ['light', 'dark']) {
    for (final scale in [1, 2]) {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '$body<script>$_kMeasure</script>',
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: tailwind,
        theme: theme,
        additionalHeadHtml:
            '''
$icons
<style>
html { font-size: ${16 * scale}px; }
body { padding: 24px; background: rgb(var(--coui-surface)); color: rgb(var(--coui-on-surface)); }
h1,h2,p { margin: 12px 0; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, 190px); gap: 16px; }
.bounded { width: 160px; border: 1px dashed gray; }
.phone-auth { width: 280px; display: flex; justify-content: center; margin: 12px 0; border: 1px dashed gray; }
.completion { width: 120px; margin: 12px 0; border: 1px dashed gray; }
.natural { display: flex; align-items: center; gap: 8px; margin: 12px 0; }
.scroll { overflow-x: auto; }
.unbounded { width: max-content; }
</style>''',
      );
      File('${output.path}/$theme-${scale}x.html').writeAsStringSync(html);
    }
  }
  File('${output.path}/index.html').writeAsStringSync('''
<!doctype html><title>Badge wrapping preview</title>
<h1>Badge wrapping preview</h1>
<ul>${[
    for (final theme in ['light', 'dark'])
      for (final scale in [1, 2]) '<li><a href="$theme-${scale}x.html">$theme ${scale}x</a></li>',
  ].join()}</ul>
<p>Each page reports bounded cases whose content exceeds the badge or container.</p>
''');
  stdout.writeln('Preview: ${output.absolute.path}/index.html');
}

const _kMeasure = '''
window.addEventListener('load', () => setTimeout(() => {
  const cases = [...document.querySelectorAll('[data-case]')].map(host => {
    const badge = host.firstElementChild;
    const box = badge.getBoundingClientRect();
    const children = [...badge.children].filter(el => el.tagName !== 'STYLE');
    const overflow = children.some(el => {
      const r = el.getBoundingClientRect();
      return r.left < box.left - 1 || r.right > box.right + 1 || r.bottom > box.bottom + 1 || el.scrollWidth > el.clientWidth + 1;
    }) || box.width > host.clientWidth + 1;
    return {case: host.dataset.case, width: box.width, height: box.height, overflow};
  });
  window.badgeWrappingResults = cases;
  document.querySelector('#result').textContent = JSON.stringify({failures: cases.filter(c => c.overflow), checked: cases.length, cases}, null, 2);
}, 1000));
''';
