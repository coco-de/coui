import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  test(
    'Input durations survive optimized rendering, motion and state changes',
    () async {
      final dir = Directory.systemTemp.createTempSync('coui-input-durations-');
      final entry = File('${dir.path}/entry.dart')..writeAsStringSync(_fixture);
      final js = File('${dir.path}/entry.js');
      final compiled = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '-Djaspr.flags.release=true',
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        entry.path,
        '-o',
        js.path,
      ]);
      expect(
        compiled.exitCode,
        0,
        reason: '${compiled.stdout}\n${compiled.stderr}',
      );
      final browser = await launchCaptureBrowser(width: 1200, height: 1800);
      try {
        final page = await browser.newPage();
        final errors = <String>[];
        page.onError.listen((e) => errors.add('$e'));
        await page.setOfflineMode(true);
        Future<List<Map<String, dynamic>>> measure() async =>
            (await page.evaluate<List<dynamic>>(
              _measure,
            )).cast<Map<String, dynamic>>();
        final observations = <Object>[];
        for (final theme in ['light', 'dark']) {
          final file = File('${dir.path}/$theme.html')
            ..writeAsStringSync(
              buildOfflineTailwindHarnessHtml(
                bodyHtml: '<script>${js.readAsStringSync()}</script>',
                themeConfig: ThemeConfig.defaults(),
                theme: theme,
                vendoredTailwindScript: loadVendoredTailwindScript(),
                additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
                animationFreezeCss: '',
              ),
            );
          await page.emulateMediaFeatures([
            pptr.MediaFeature.prefersReducedMotion('no-preference'),
          ]);
          await page.goto(file.uri.toString(), wait: .load);
          await page.waitForSelector(
            '#case-color-empty-arbitrary .transition-colors',
          );
          await page.evaluate<void>('() => document.fonts.ready');
          final normal = await measure();
          expect(normal.length, greaterThan(50));
          expect(normal.map((e) => e['case']).toSet(), hasLength(56));
          for (final row in normal) {
            expect(
              row['duration'],
              row['expected'],
              reason: '$theme normal $row',
            );
          }
          await page.emulateMediaFeatures([
            pptr.MediaFeature.prefersReducedMotion('reduce'),
          ]);
          final reduced = await measure();
          expect(reduced.length, normal.length);
          for (var i = 0; i < reduced.length; i++) {
            final row = reduced[i];
            final ms = row['expected'] as num;
            final expected =
                CoreReducedMotion.isTransitionMotion(
                  Duration(milliseconds: ms.toInt()),
                )
                ? 0
                : ms;
            expect(row['duration'], expected, reason: '$theme reduce $row');
            for (final field in [
              'case',
              'property',
              'geometry',
              'role',
              'disabled',
              'checked',
              'tabIndex',
            ]) {
              expect(
                row[field],
                normal[i][field],
                reason: '$theme $field $row',
              );
            }
          }
          await page.emulateMediaFeatures([
            pptr.MediaFeature.prefersReducedMotion('no-preference'),
          ]);
          await page.evaluate<void>(
            '() => document.documentElement.style.setProperty( '
            "'--coui-duration-150', '73ms')",
          );
          final remapped = await measure();
          for (final row in remapped) {
            expect(
              row['duration'],
              row['expected'] == 150 ? 73 : row['expected'],
              reason: '$theme remapped $row',
            );
          }
          await page.evaluate<void>(
            '() => document.documentElement.style.removeProperty( '
            "'--coui-duration-150')",
          );
          await page.type('#case-text-field-arbitrary input', 'Z');
          final before = await page.evaluate<Map<String, dynamic>>('''
() => { const e=document.querySelector('#case-text-field-arbitrary input');
return {value:e.value,start:e.selectionStart,end:e.selectionEnd,active:document.activeElement===e}; }
''');
          expect(before['value'], contains('Z'));
          expect(before['active'], isTrue);
          await page.evaluate<void>(
            "() => document.getElementById('toggle').click()",
          );
          await page.waitForFunction(
            "() => document.getElementById('stage').textContent === 'true'",
          );
          final after = await page.evaluate<Map<String, dynamic>>('''
() => { const e=document.querySelector('#case-text-field-arbitrary input');
return {value:e.value,start:e.selectionStart,end:e.selectionEnd,active:document.activeElement===e}; }
''');
          expect(
            after,
            before,
            reason: '$theme caller input survives parent state update',
          );
          await page.focus('#case-otp-arbitrary input');
          final focused = await measure();
          for (final row in focused) {
            expect(
              row['duration'],
              row['expected'],
              reason: '$theme focused/state $row',
            );
          }
          await page.click('#case-color-arbitrary .transition-colors');
          await page.waitForSelector(
            '[data-coui-overlay-panel] '
            '.transition-shadow[style*="background-color"]',
          );
          final swatches = await page.evaluate<List<dynamic>>('''
() => [...document.querySelectorAll('[data-coui-overlay-panel] .transition-shadow[style*="background-color"]')].map(e=>({duration:parseFloat(getComputedStyle(e).transitionDuration)*1000,color:getComputedStyle(e).backgroundColor}))
''');
          expect(swatches, hasLength(2));
          for (final swatch in swatches.cast<Map<String, dynamic>>()) {
            expect(
              swatch['duration'],
              123,
              reason: '$theme recent swatch $swatch',
            );
          }
          await page.keyboard.press(pptr.Key.escape);
          observations.add({
            'theme': theme,
            'normal': normal,
            'reduced': reduced,
            'remapped': remapped,
            'focused': focused,
            'recentSwatches': swatches,
          });
          expect(errors, isEmpty);
        }
        final artifactPath = Platform.environment['COUI_DURATION_ARTIFACTS'];
        if (artifactPath != null) {
          Directory(artifactPath).createSync(recursive: true);
          File(
            '$artifactPath/input-observations.json',
          ).writeAsStringSync(jsonEncode(observations));
        }
      } finally {
        await browser.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}

const _measure = '''
() => [...document.querySelectorAll('[data-kind]')].flatMap(c => {
 const kind=c.dataset.kind;
 let nodes=[];
 if(kind==='text-field') nodes=[...c.querySelectorAll('input')];
 else if(kind==='text-area') nodes=[...c.querySelectorAll('textarea')];
 else if(kind==='otp') nodes=[...c.querySelectorAll('.transition-all')];
 else if(kind==='radio') nodes=[...c.querySelectorAll('.transition-colors,.transition-opacity,.transition-transform')];
 else if(kind==='color') nodes=[c.querySelector('.transition-colors')];
 return nodes.filter(Boolean).map(e=>{const s=getComputedStyle(e),r=e.getBoundingClientRect();
 const expected=kind==='radio'&&e.classList.contains('transition-transform')?+c.dataset.dot:+c.dataset.clock;
 return {case:c.id,expected,duration:parseFloat(s.transitionDuration)*1000,
 property:s.transitionProperty,geometry:[r.width,r.height],role:e.getAttribute('role'),
 disabled:e.getAttribute('disabled'),checked:e.getAttribute('aria-checked'),tabIndex:e.getAttribute('tabindex')}; });
})
''';

const _fixture = r'''
import 'package:coui_web/coui_web.dart';

void main() => runApp(
  CoUIWeb(
    theme: .coui,
    initialRecentColors: const [CoreColor(0xff123456), CoreColor(0xff112233)],
    child: const Probe(),
  ),
);

class Probe extends StatefulComponent {
  const Probe({super.key});
  @override
  State<Probe> createState() => ProbeState();
}

class ProbeState extends State<Probe> {
  bool stage = false;
  int changes = 0;
  @override
  Component build(BuildContext context) {
    const durations = <String, Duration?>{
      'default': null,
      'zero': Duration.zero,
      'token': Duration(milliseconds: 150),
      'arbitrary': Duration(milliseconds: 123),
      'display': Duration(milliseconds: 2000),
    };
    final cases = <Component>[];
    for (final entry in durations.entries) {
      final d = entry.value;
      final name = entry.key;
      Component wrap(
        String suffix,
        String kind,
        int fallback,
        Component child, {
        int? dot,
      }) => div(
        [child],
        id: 'case-$suffix-$name',
        attributes: {
          'data-kind': kind,
          'data-clock': '${d?.inMilliseconds ?? fallback}',
          'data-dot': '${dot ?? d?.inMilliseconds ?? fallback}',
        },
      );
      cases.add(
        wrap(
          'text-field',
          'text-field',
          CoreTextFieldStyle.defaultTransitionDuration.inMilliseconds,
          TextField(
            initialValue: 'A',
            onChanged: (_) => setState(() => changes++),
            textFieldStyle: CoreTextFieldStyle(transitionDuration: d),
          ),
        ),
      );
      cases.add(
        wrap(
          'text-area',
          'text-area',
          CoreTextAreaStyle.defaultTransitionDuration.inMilliseconds,
          TextArea(
            initialValue: 'Area',
            textAreaStyle: CoreTextAreaStyle(transitionDuration: d),
          ),
        ),
      );
      cases.add(
        wrap(
          'text-area-footer',
          'text-area',
          CoreTextAreaStyle.defaultTransitionDuration.inMilliseconds,
          TextArea(
            initialValue: 'Area',
            footer: const Text('Footer'),
            textAreaStyle: CoreTextAreaStyle(transitionDuration: d),
          ),
        ),
      );
      for (final variant in CoreRadioGroupVariant.values) {
        cases.add(
          wrap(
            'radio-${variant.name}',
            'radio',
            CoreRadioGroupStyle.defaultColorTransitionDuration.inMilliseconds,
            RadioGroup(
              value: stage ? 'b' : 'a',
              onChanged: (_) => setState(() => changes++),
              options: const [
                (value: 'a', label: 'A'),
                (value: 'b', label: 'B'),
              ],
              variant: variant,
              radioGroupStyle: CoreRadioGroupStyle(
                colorTransitionDuration: d,
                dotTransitionDuration: d,
              ),
            ),
            dot:
                d?.inMilliseconds ??
                CoreRadioGroupStyle.defaultDotTransitionDuration.inMilliseconds,
          ),
        );
      }
      if (name == 'arbitrary')
        cases.add(
          wrap(
            'radio-clocks',
            'radio',
            123,
            RadioGroup(
              value: 'a',
              options: const [(value: 'a', label: 'A')],
              radioGroupStyle: const CoreRadioGroupStyle(
                colorTransitionDuration: Duration(milliseconds: 123),
                dotTransitionDuration: Duration(milliseconds: 371),
              ),
            ),
            dot: 371,
          ),
        );
      cases.add(
        wrap(
          'radio-disabled',
          'radio',
          CoreRadioGroupStyle.defaultColorTransitionDuration.inMilliseconds,
          RadioGroup(
            enabled: false,
            value: 'a',
            options: const [(value: 'a', label: 'A')],
            radioGroupStyle: CoreRadioGroupStyle(
              colorTransitionDuration: d,
              dotTransitionDuration: d,
            ),
          ),
          dot:
              d?.inMilliseconds ??
              CoreRadioGroupStyle.defaultDotTransitionDuration.inMilliseconds,
        ),
      );
      cases.add(
        wrap(
          'otp',
          'otp',
          CoreInputOtpStyle.defaultTransitionDuration.inMilliseconds,
          InputOtp(
            length: 4,
            initialValue: '12',
            inputOtpStyle: CoreInputOtpStyle(transitionDuration: d),
          ),
        ),
      );
      cases.add(
        wrap(
          'otp-disabled',
          'otp',
          CoreInputOtpStyle.defaultTransitionDuration.inMilliseconds,
          InputOtp(
            enabled: false,
            length: 4,
            initialValue: '12',
            inputOtpStyle: CoreInputOtpStyle(transitionDuration: d),
          ),
        ),
      );
      cases.add(
        wrap(
          'color',
          'color',
          CoreColorPickerStyle.defaultTransitionDuration.inMilliseconds,
          ColorPicker(
            color: '#123456',
            colorPickerStyle: CoreColorPickerStyle(transitionDuration: d),
          ),
        ),
      );
      cases.add(
        wrap(
          'color-empty',
          'color',
          CoreColorPickerStyle.defaultTransitionDuration.inMilliseconds,
          ColorPicker(
            color: '',
            colorPickerStyle: CoreColorPickerStyle(transitionDuration: d),
          ),
        ),
      );
      cases.add(
        wrap(
          'color-disabled',
          'color',
          CoreColorPickerStyle.defaultTransitionDuration.inMilliseconds,
          ColorPicker(
            enabled: false,
            color: '#123456',
            colorPickerStyle: CoreColorPickerStyle(transitionDuration: d),
          ),
        ),
      );
    }
    return div([
      button(
        [const Text('Toggle')],
        id: 'toggle',
        onClick: () => setState(() => stage = !stage),
      ),
      span([Text('$stage')], id: 'stage'),
      span([Text('$changes')], id: 'changes'),
      ...cases,
    ]);
  }
}
''';
