// The toolbar a Web `RichEditor` floats over selected text, in a real Chrome.
//
// The Web unit tests pin the toolbar's markup and chrome
// (`packages/coui_web/test/components/form/rich_editor_selection_toolbar_test.dart`).
// When it shows and where it lands are the browser's to say — the selection,
// the focus and every box come from the DOM, and the VM has none. So this
// file compiles a client entry
// (`src/web/rich_editor_selection_toolbar_entry.dart`), selects text in it
// the way a user does, and reads the boxes back.
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../src/web/offline_tailwind_harness.dart';

String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

const String _toolbar = '[role=toolbar][aria-label="Selection formatting"]';

/// Focuses the editor in `#id` and selects the text of its last paragraph
/// (its first with [first]) — or collapses the selection to its end when
/// [collapse] is set.
String _select(String id, {bool collapse = false, bool first = false}) =>
    '''
() => {
  const surface = document.querySelector('#$id [contenteditable]');
  surface.focus();
  const range = document.createRange();
  range.selectNodeContents(
      surface.${first ? 'firstElementChild' : 'lastElementChild'});
  if ($collapse) range.collapse(false);
  const selection = getSelection();
  selection.removeAllRanges();
  selection.addRange(range);
}''';

/// Whether the toolbar is in the page, placed, and done moving in.
///
/// Done is read from the animations themselves: the box scales and the panel
/// inside it fades, so the opacity of the box (which only says it is placed)
/// does not say either has finished.
const String _shown =
    '''
() => {
  const bar = document.querySelector('$_toolbar');
  if (bar === null) return false;
  const wrapper = bar.parentElement.parentElement;
  if (wrapper.style.top === '') return false;
  return getComputedStyle(bar.parentElement).opacity === '1' &&
      bar.parentElement.getAnimations({subtree: true})
          .every((a) => a.playState === 'finished');
}''';

const String _gone = '''
() => document.querySelector('$_toolbar') === null''';

/// The boxes the claims are about, as JSON: the toolbar panel, the selected
/// text, the surface of the editor in `#id`, and what is selected.
String _read(String id) =>
    '''
() => {
  const box = (r) => ({left: r.left, top: r.top, right: r.right,
      bottom: r.bottom, width: r.width, height: r.height});
  const bar = document.querySelector('$_toolbar');
  const selection = getSelection();
  const surface = document.querySelector('#$id [contenteditable]');
  const own = document.querySelector('#$id [role=toolbar]');
  const shown = (b) => b.offsetParent !== null
      && getComputedStyle(b).visibility !== 'hidden'
      && b.closest('[aria-hidden=true]') === null;
  return JSON.stringify({
    bar: bar === null ? null : box(bar.getBoundingClientRect()),
    selected: selection.rangeCount === 0
        ? null
        : box(selection.getRangeAt(0).getBoundingClientRect()),
    text: selection.toString(),
    html: surface.innerHTML,
    focusInSurface: document.activeElement === surface,
    focusInBar: bar !== null && bar.contains(document.activeElement),
    ownToolbar: own === null ? null : box(own.getBoundingClientRect()),
    surface: box(surface.getBoundingClientRect()),
    shownButtons: bar === null ? [] : [...bar.querySelectorAll('button')]
        .filter(shown).map((b) => b.getAttribute('aria-label')),
  });
}''';

typedef _Box = ({
  double left,
  double top,
  double right,
  double bottom,
  double width,
  double height,
});

_Box? _box(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  double n(String key) => (json[key] as num).toDouble();

  return (
    left: n('left'),
    top: n('top'),
    right: n('right'),
    bottom: n('bottom'),
    width: n('width'),
    height: n('height'),
  );
}

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();
  final skip = chromePath == null;

  group('RichEditorSelectionToolbarProbe', () {
    late Directory fixture;
    late File html;

    setUpAll(() async {
      if (skip) return;
      fixture = Directory.systemTemp.createTempSync(
        'coui-parity-rich-editor-selection-toolbar-',
      );
      final js = p.join(fixture.path, 'entry.js');
      final result = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '-o',
        js,
        'tool/parity/src/web/rich_editor_selection_toolbar_entry.dart',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      html = File(p.join(fixture.path, 'editor.html'))
        ..writeAsStringSync('''
<!doctype html>
<html data-theme="light">
<head>
<meta charset="utf-8">
<style>body { margin: 0; }</style>
<script>$vendoredScript</script>
<script>${themeConfig.tailwindConfig}</script>
<style>${themeConfig.cssVariables}</style>
</head>
<body>
<script>${File(js).readAsStringSync()}</script>
</body>
</html>
''');
    });

    tearDownAll(() {
      if (!skip) fixture.deleteSync(recursive: true);
    });

    /// Opens the page in a fresh browser [width] wide, waits for the editors
    /// to hydrate, and runs [body].
    Future<void> onPage(
      Future<void> Function(pptr.Page chrome) body, {
      int width = 1024,
    }) async {
      final browser = await pptr.puppeteer.launch(executablePath: chromePath);
      try {
        final chrome = await browser.newPage();
        await chrome.setOfflineMode(true);
        await chrome.setViewport(
          pptr.DeviceViewport(width: width, height: 768),
        );
        final _ = await chrome.goto(
          Uri.file(html.path).toString(),
          wait: pptr.Until.load,
        );
        await chrome.waitForFunction('''
() => {
  const surface = document.querySelector('#readonly [contenteditable]');
  return surface !== null && surface.children.length > 0;
}''');
        await body(chrome);
      } finally {
        await browser.close();
      }
    }

    Future<Map<String, dynamic>> read(pptr.Page chrome, String id) async =>
        jsonDecode(await chrome.evaluate<String>(_read(id)))
            as Map<String, dynamic>;

    Future<void> selectAndWait(pptr.Page chrome, String id) async {
      await chrome.evaluate<void>(_select(id));
      await chrome.waitForFunction(_shown);
    }

    /// Lets the page run for [ms] — longer than the toolbar takes to open —
    /// before a claim that it did not.
    Future<void> settle([int ms = 400]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    test(
      'sits centred over the selection, 8 above it',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        final seen = await read(chrome, 'main');
        final bar = _box(seen['bar'])!;
        final selected = _box(seen['selected'])!;
        expect(seen['text'], 'hello world');
        expect(bar.bottom, closeTo(selected.top - 8, 0.6));
        expect(
          bar.left + bar.width / 2,
          closeTo(selected.left + selected.width / 2, 0.6),
        );
        // 4 above and below 32-tall buttons, the panel's 1 line lying over
        // the inset — 40, as the Flutter panel and the canvas draw it.
        expect(bar.height, closeTo(40, 0.6));
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'sits below a selection with no room above it',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'top');
        final seen = await read(chrome, 'top');
        final bar = _box(seen['bar'])!;
        final selected = _box(seen['selected'])!;
        expect(selected.top, lessThan(bar.height + 8));
        expect(bar.top, closeTo(selected.bottom + 8, 0.6));
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'is held inside the viewport at its edge',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'edge');
        final seen = await read(chrome, 'edge');
        final bar = _box(seen['bar'])!;
        final selected = _box(seen['selected'])!;
        // Centred it would start left of the page.
        expect(
          selected.left + selected.width / 2 - bar.width / 2,
          lessThan(0),
        );
        expect(bar.left, closeTo(8, 0.6));
        expect(bar.bottom, closeTo(selected.top - 8, 0.6));
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'waits for the pointer to come up while a drag selects',
      () => onPage((chrome) async {
        final line = _box(
          jsonDecode(
            await chrome.evaluate<String>('''
() => {
  const range = document.createRange();
  range.selectNodeContents(
      document.querySelector('#main [contenteditable]').lastElementChild);
  const r = range.getBoundingClientRect();
  return JSON.stringify({left: r.left, top: r.top, right: r.right,
      bottom: r.bottom, width: r.width, height: r.height});
}'''),
          ),
        )!;
        final y = line.top + line.height / 2;
        await chrome.mouse.move(Point(line.left + 1, y));
        await chrome.mouse.down();
        await chrome.mouse.move(Point(line.left + 30, y), steps: 4);
        await chrome.mouse.move(Point(line.right - 1, y), steps: 4);
        await settle();
        final dragging = await read(chrome, 'main');
        expect(dragging['text'], isNotEmpty);
        expect(dragging['bar'], isNull, reason: 'the pointer is still down');

        await chrome.mouse.up();
        await chrome.waitForFunction(_shown);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'goes when the selection collapses',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        await chrome.evaluate<void>(_select('main', collapse: true));
        await chrome.waitForFunction(_gone);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'Escape closes it until the selection changes',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        await chrome.keyboard.press(pptr.Key.escape);
        await chrome.waitForFunction(_gone);
        final seen = await read(chrome, 'main');
        expect(seen['text'], 'hello world', reason: 'the selection is kept');
        expect(seen['focusInSurface'], isTrue);
        await settle();
        expect((await read(chrome, 'main'))['bar'], isNull);
        // Another selection brings it back.
        await chrome.keyboard.down(pptr.Key.shift);
        await chrome.keyboard.press(pptr.Key.arrowLeft);
        await chrome.keyboard.up(pptr.Key.shift);
        await chrome.waitForFunction(_shown);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'a press formats the selection and leaves the toolbar open',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        await chrome.click('$_toolbar button[aria-label="Bold"]');
        await settle();
        final seen = await read(chrome, 'main');
        expect(seen['html'], contains('hello world</'));
        expect(seen['html'], matches(RegExp('<(b|strong)[ >]')));
        expect(seen['text'], 'hello world', reason: 'the selection is kept');
        expect(seen['bar'], isNotNull);
        expect(seen['focusInSurface'], isTrue);
        // Both toolbars hold the button down.
        final pressed = await chrome.evaluate<List<dynamic>>('''
() => [...document.querySelectorAll(
        '#main button[aria-label="Bold"], $_toolbar button[aria-label="Bold"]')]
    .map((b) => b.getAttribute('aria-pressed'))''');
        expect(pressed, ['true', 'true']);
        // No image button over the selection.
        final images = await chrome.evaluate<int>(
          '''
() => document.querySelectorAll('$_toolbar button[aria-label="Image"]').length''',
        );
        expect(images, 0);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'its block-type menu sets the block and leaves the toolbar open',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        await chrome.click('$_toolbar button[aria-label^="Block type"]');
        await chrome.waitForFunction('''
() => document.querySelectorAll('[role=menuitemradio]').length === 4''');
        expect((await read(chrome, 'main'))['bar'], isNotNull);
        await chrome.evaluate<void>('''
() => [...document.querySelectorAll('[role=menuitemradio]')]
    .find((row) => row.textContent.includes('Heading 2')).click()''');
        await chrome.waitForFunction('''
() => document.querySelector('#main [contenteditable] h2') !== null''');
        await settle();
        final seen = await read(chrome, 'main');
        expect(seen['bar'], isNotNull);
        expect(seen['focusInSurface'], isTrue);
        // Both block-type buttons — the one in the box and the floating one —
        // read the heading.
        final labels = await chrome.evaluate<List<dynamic>>('''
() => [...document.querySelectorAll(
        '#main button[aria-label^="Block type"], '
        + '$_toolbar button[aria-label^="Block type"]')]
    .map((b) => b.getAttribute('aria-label'))''');
        expect(labels, ['Block type: Heading 2', 'Block type: Heading 2']);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'Alt+F10 moves the focus into it, Escape brings it back',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        await chrome.keyboard.down(pptr.Key.alt);
        await chrome.keyboard.press(pptr.Key.f10);
        await chrome.keyboard.up(pptr.Key.alt);
        await settle();
        final inside = await read(chrome, 'main');
        expect(inside['focusInBar'], isTrue);
        expect(inside['bar'], isNotNull);
        await chrome.keyboard.press(pptr.Key.escape);
        await chrome.waitForFunction(_gone);
        final back = await read(chrome, 'main');
        expect(back['focusInSurface'], isTrue);
        expect(back['text'], 'hello world', reason: 'the selection is kept');
        expect(_box(back['selected']), _box(inside['selected']));
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'goes when the focus leaves the editor',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        await chrome.evaluate<void>(
          "() => document.getElementById('elsewhere').focus()",
        );
        await chrome.waitForFunction(_gone);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'never shows with showSelectionToolbar off, or on a read-only editor',
      () => onPage((chrome) async {
        for (final id in ['off', 'readonly']) {
          await chrome.evaluate<void>(_select(id));
          await settle(600);
          final seen = await read(chrome, id);
          expect(seen['text'], isNotEmpty, reason: id);
          expect(seen['bar'], isNull, reason: id);
        }
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'follows the selection when the page scrolls',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        final before = _box((await read(chrome, 'main'))['bar'])!;
        await chrome.evaluate<void>('() => window.scrollBy(0, 60)');
        await settle();
        final seen = await read(chrome, 'main');
        final bar = _box(seen['bar'])!;
        final selected = _box(seen['selected'])!;
        expect(bar.top, closeTo(before.top - 60, 0.6));
        expect(bar.bottom, closeTo(selected.top - 8, 0.6));
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'a selection on the first line gets the toolbar below it, clear of the '
      'toolbar in the box',
      () => onPage((chrome) async {
        await chrome.evaluate<void>(_select('main', first: true));
        await chrome.waitForFunction(_shown);
        final seen = await read(chrome, 'main');
        final bar = _box(seen['bar'])!;
        final selected = _box(seen['selected'])!;
        final own = _box(seen['ownToolbar'])!;
        final surface = _box(seen['surface'])!;
        expect(seen['text'], 'one');
        // The screen has room above the editor; the editing area has not.
        expect(selected.top, greaterThan(bar.height + 8));
        expect(selected.top - surface.top, lessThan(bar.height + 8));
        expect(bar.top, closeTo(selected.bottom + 8, 0.6));
        expect(
          bar.top,
          greaterThan(own.bottom),
          reason: 'not over the box toolbar',
        );
        expect(
          bar.left + bar.width / 2,
          closeTo(selected.left + selected.width / 2, 0.6),
        );
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'a selection grown from the keyboard waits for it to hold still',
      () => onPage((chrome) async {
        await chrome.evaluate<void>(_select('main', collapse: true));
        await settle();
        expect((await read(chrome, 'main'))['bar'], isNull);
        const delay = CoreRichEditorContract.selectionToolbarKeyboardDelay;
        await chrome.keyboard.down(pptr.Key.shift);
        for (var i = 0; i < 4; i++) {
          await chrome.keyboard.press(pptr.Key.arrowLeft);
          // Each press comes within the delay of the one before.
          await Future<void>.delayed(delay ~/ 3);
          final seen = await read(chrome, 'main');
          expect(seen['text'], isNotEmpty, reason: 'press ${i + 1}');
          expect(seen['bar'], isNull, reason: 'press ${i + 1}: still moving');
        }
        await chrome.keyboard.up(pptr.Key.shift);
        await chrome.waitForFunction(_shown);
        // Growing it again takes the toolbar away until it holds still.
        await chrome.keyboard.down(pptr.Key.shift);
        await chrome.keyboard.press(pptr.Key.arrowLeft);
        await chrome.keyboard.up(pptr.Key.shift);
        await chrome.waitForFunction(_gone);
        await chrome.waitForFunction(_shown);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'goes when the selection scrolls out of view, back when it returns',
      () => onPage((chrome) async {
        // The last line of a text taller than its box: selected while out
        // of view, the toolbar has nothing to sit over.
        const toBottom = '''
() => {
  const surface = document.querySelector('#tall [contenteditable]');
  surface.scrollTop = surface.scrollHeight;
}''';
        const toTop = '''
() => { document.querySelector('#tall [contenteditable]').scrollTop = 0; }''';
        await chrome.evaluate<void>(_select('tall'));
        await settle();
        final hidden = await read(chrome, 'tall');
        expect(hidden['text'], 'line 29');
        expect(hidden['bar'], isNull, reason: 'the line is below the box');
        // Scrolled into view — the text, not the page — it shows.
        await chrome.evaluate<void>(toBottom);
        await chrome.waitForFunction(_shown);
        final shown = await read(chrome, 'tall');
        final bar = _box(shown['bar'])!;
        final selected = _box(shown['selected'])!;
        expect(bar.bottom, closeTo(selected.top - 8, 0.6));
        // Out of view again, it goes; the selection stays.
        await chrome.evaluate<void>(toTop);
        await chrome.waitForFunction(_gone);
        expect((await read(chrome, 'tall'))['text'], 'line 29');
        // And back when the line returns.
        await chrome.evaluate<void>(toBottom);
        await chrome.waitForFunction(_shown);
        expect((await read(chrome, 'tall'))['text'], 'line 29');
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'too narrow for its buttons it folds the quote into a more menu, '
      'the block-type menu staying, and never wraps',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'top');
        final seen = await read(chrome, 'top');
        final bar = _box(seen['bar'])!;
        expect(bar.height, closeTo(40, 0.6), reason: 'one row');
        expect(bar.width, lessThanOrEqualTo(360 - 2 * 8 + 0.6));
        final shown = (seen['shownButtons'] as List<dynamic>).cast<String>();
        expect(shown.first, 'Block type: Text');
        expect(shown.last, 'More');
        expect(shown, isNot(contains('Quote')));
        // Whatever else folded went in the fold order: a button that shows
        // folds after every one that does not.
        const order = CoreRichEditorFormat.selectionToolbarFoldOrder;
        const labels = {
          CoreRichEditorFormat.quote: 'Quote',
          CoreRichEditorFormat.bulletedList: 'Bulleted list',
          CoreRichEditorFormat.link: 'Link',
          CoreRichEditorFormat.code: 'Code',
          CoreRichEditorFormat.strikethrough: 'Strikethrough',
          CoreRichEditorFormat.italic: 'Italic',
          CoreRichEditorFormat.bold: 'Bold',
        };
        var folding = true;
        for (final unit in order) {
          final shows = shown.contains(labels[unit.first]);
          if (shows) folding = false;
          if (!folding) expect(shows, isTrue, reason: labels[unit.first]);
        }
        // The more menu lists the folded formats as checkbox rows; picking
        // the quote applies it, and its row is checked afterwards.
        await chrome.click('$_toolbar button[aria-label="More"]');
        await chrome.waitForFunction('''
() => document.querySelectorAll('[role=menuitemcheckbox]').length > 0''');
        final rows = await chrome.evaluate<List<dynamic>>('''
() => [...document.querySelectorAll('[role=menuitemcheckbox]')]
    .map((row) => row.innerText.trim())''');
        expect(rows.last, 'Quote');
        expect(rows.length + shown.length - 2, 9);
        await chrome.evaluate<void>('''
() => [...document.querySelectorAll('[role=menuitemcheckbox]')]
    .find((row) => row.textContent.includes('Quote')).click()''');
        await chrome.waitForFunction('''
() => document.querySelector('#top [contenteditable] blockquote') !== null''');
      }, width: 360),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'nothing folds with room for every button',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        final shown = ((await read(chrome, 'main'))['shownButtons'] as List)
            .cast<String>();
        expect(shown, hasLength(10));
        expect(shown, isNot(contains('More')));
        expect(shown.last, 'Quote');
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'the panel: 10 corner, 1 line, 4 inset with 12 where the text starts',
      () => onPage((chrome) async {
        await selectAndWait(chrome, 'main');
        final style =
            jsonDecode(
                  await chrome.evaluate<String>('''
() => {
  const bar = document.querySelector('$_toolbar');
  const cs = getComputedStyle(bar);
  const panel = bar.getBoundingClientRect();
  const first = bar.querySelector('button').getBoundingClientRect();
  const buttons = bar.querySelectorAll('button');
  const shown = [...buttons].filter((b) => b.offsetParent !== null
      && getComputedStyle(b).visibility !== 'hidden');
  const last = shown[shown.length - 1].getBoundingClientRect();
  return JSON.stringify({
    radius: cs.borderTopLeftRadius,
    border: cs.borderTopWidth,
    shadow: cs.boxShadow,
    start: first.left - panel.left,
    end: panel.right - last.right,
    top: first.top - panel.top,
    bottom: panel.bottom - first.bottom,
    panelHeight: panel.height,
    buttons: buttons.length,
    shownButtons: shown.length,
    topLayer: bar.parentElement.parentElement.matches(':popover-open'),
  });
}'''),
                )
                as Map<String, dynamic>;
        expect(style['radius'], '10px');
        expect(style['border'], '1px');
        expect(style['shadow'], isNot('none'));
        // The insets are measured from the border box, and the line overlaps
        // the padding as the Flutter panel's decoration does: the row starts
        // 12 from the edge and ends 4 from it, and the panel is 40 tall with
        // the line kept — as the Flutter panel and the canvas.
        expect(style['start'], closeTo(12, 0.6));
        expect(style['end'], closeTo(4, 0.6));
        expect(style['top'], closeTo(4, 0.6));
        expect(style['bottom'], closeTo(4, 0.6));
        expect(style['panelHeight'], closeTo(40, 0.6));
        // Ten buttons show; the "more" button is in the DOM out of sight.
        expect(style['buttons'], 11);
        expect(style['shownButtons'], 10);
        expect(style['topLayer'], isTrue);
      }),
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
