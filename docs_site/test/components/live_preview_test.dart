import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String livePreviewSource;
  late String mainServerSource;
  late String siteHeadSource;

  setUpAll(() {
    livePreviewSource =
        File(
          'lib/components/live_preview.dart',
        ).readAsStringSync() +
        File('lib/components/live_preview_panel.dart').readAsStringSync() +
        File('lib/components/preview_gallery.dart').readAsStringSync();
    // 엔트리포인트, 두 레이아웃이 함께 싣는 머리(`site_chrome.dart`), 그리고
    // 프리뷰의 누름을 받는 정적 스크립트 — 셋이 함께 "사이트가 프리뷰에
    // 필요한 것을 싣는다" 를 이룬다.
    mainServerSource =
        File('lib/main.server.dart').readAsStringSync() +
        File('lib/layouts/site_chrome.dart').readAsStringSync() +
        File('web/docs-shell.js').readAsStringSync();
    siteHeadSource = File('../docs_core/lib/site_head.dart').readAsStringSync();
  });

  group('LivePreview component structure', () {
    test('extends CustomComponent', () {
      expect(livePreviewSource, contains('extends CustomComponent'));
    });

    test('parses component attribute', () {
      expect(livePreviewSource, contains("attributes['component']"));
    });

    test('parses variant attribute', () {
      expect(livePreviewSource, contains("attributes['variant']"));
    });

    test('parses variants attribute for gallery mode', () {
      expect(livePreviewSource, contains("attributes['variants']"));
    });

    test('supports single variant mode', () {
      expect(livePreviewSource, contains('LivePreviewPanel'));
    });

    test('supports variant gallery mode', () {
      expect(livePreviewSource, contains('PreviewGallery'));
    });

    test('renders Web and Flutter preview panes', () {
      expect(livePreviewSource, contains('preview-pane preview-web'));
      expect(livePreviewSource, contains('preview-pane preview-flutter'));
    });

    test('renders code tabs with Web and Flutter labels', () {
      expect(livePreviewSource, contains("'data-tab': 'web'"));
      expect(livePreviewSource, contains("'data-tab': 'flutter'"));
    });

    test('includes copy button', () {
      expect(livePreviewSource, contains('preview-copy-btn'));
    });
  });

  group('LivePreview imports', () {
    test('imports web preview component', () {
      // The web pane is rendered via the `web_preview.dart` component, which
      // internally owns the web preview registry (LivePreview no longer
      // imports `web_registry.dart` directly).
      expect(livePreviewSource, contains("web_preview.dart"));
    });

    test('imports code registry', () {
      expect(livePreviewSource, contains("code_registry.dart"));
    });

    test('imports flutter code registry', () {
      expect(livePreviewSource, contains("flutter_code_registry.dart"));
    });

    test('imports flutter preview component', () {
      expect(livePreviewSource, contains("flutter_preview.dart"));
    });
  });

  group('main.server.dart integration', () {
    test('registers LivePreview in ContentApp components', () {
      expect(mainServerSource, contains('LivePreview()'));
    });

    test('includes flutter_bootstrap.js script', () {
      expect(mainServerSource, contains('flutter_bootstrap.js'));
    });

    test('includes highlight.js for code blocks', () {
      expect(mainServerSource, contains('highlight.js'));
    });

    test('includes copy button click handler', () {
      expect(mainServerSource, contains('preview-copy-btn'));
    });

    test('includes tab switching handler', () {
      expect(mainServerSource, contains('preview-code-tab'));
    });

    test('includes LivePreview CSS styles', () {
      expect(mainServerSource, contains('docsPreviewStyles()'));
      expect(siteHeadSource, contains('_livePreviewStyles'));
    });

    test('includes preview preflight reset', () {
      expect(mainServerSource, contains('docsPreviewStyles()'));
      expect(siteHeadSource, contains('_previewPreflightReset'));
    });
  });

  // The `/embed` route backs docs_app's Web preview pane, so it has to resolve
  // the design system exactly like the docs pages do. Sharing one definition
  // (rather than a copy per entrypoint) is what keeps them from drifting.
  group('shared head', () {
    test('site and embed both source the shared head', () {
      expect(mainServerSource, contains('docsSharedHead()'));
      expect(
        File('../docs_core/lib/embed/embed_page.dart').readAsStringSync(),
        contains('docsSharedHead()'),
      );
    });

    test('shared head owns the Tailwind config, CSS variables and fonts', () {
      expect(siteHeadSource, contains('tailwindConfig'));
      expect(siteHeadSource, contains('cssVariables'));
      expect(siteHeadSource, contains('pretendard.min.css'));
      expect(mainServerSource, isNot(contains('tailwindConfig')));
      expect(mainServerSource, isNot(contains('cssVariables')));
    });

    // The Web side's mono face is read from the Flutter build's copy of the
    // GeistMono masters coui_flutter declares — the same bytes the Flutter
    // pane draws. That path exists only for a master coui_flutter's pubspec
    // declares, so every weight the head names has to be declared there; a
    // missing one would 404 on the page with nothing else failing.
    test('the mono @font-face reads masters coui_flutter declares', () {
      final pubspec = File(
        '../packages/coui_flutter/pubspec.yaml',
      ).readAsStringSync();
      expect(
        siteHeadSource,
        contains('/assets/packages/coui_flutter/lib/fonts/GeistMono-'),
      );
      final masters = RegExp(
        r"^\s*\d{3}: '(\w+)',$",
        multiLine: true,
      ).allMatches(siteHeadSource.split('const _kMonoMasters = {')[1].split('};')[0]).map((m) => m[1]!).toList();
      expect(masters, ['Regular', 'Medium', 'SemiBold', 'Bold']);
      for (final name in masters) {
        expect(
          pubspec,
          contains('lib/fonts/GeistMono-$name.otf'),
          reason: 'GeistMono-$name is not a declared coui_flutter asset',
        );
      }
    });
  });

  // The preflight reset neutralises ambient defaults for component previews.
  // It is only ever allowed to beat the UA sheet — never a class a component
  // emitted. Written as plain element selectors (`.preview-content a` = 0,1,1)
  // it outranks single-class utilities (0,1,0) and erases component chrome:
  // `Link` emitted `underline text-primary` and rendered as plain unlinked
  // text. Zero specificity is what keeps that from coming back, and it only
  // holds together with `not-content` — without it `jaspr_content`'s prose
  // rules (0,1,0) outrank the reset instead and restore their own `<p>`
  // margins and link underlines. Neither half is safe alone.
  group('preview preflight reset specificity', () {
    /// The `css('…')` selectors declared inside `_previewPreflightReset()`.
    List<String> resetSelectors() {
      final body = siteHeadSource.split('_previewPreflightReset() => [')[1].split('\n];')[0];
      return RegExp(
        r"""css\(\s*'([^']*)'""",
        multiLine: true,
      ).allMatches(body).map((m) => m.group(1)!).toList();
    }

    test('reset declares selectors (guard is not silently matching nothing)', () {
      expect(resetSelectors(), isNotEmpty);
    });

    test('every reset selector carries zero specificity', () {
      // Strip the `:where(…)` groups — whatever is left is what still carries
      // weight. Only combinators and whitespace may remain.
      final offenders = [
        for (final selector in resetSelectors())
          if (!RegExp(
            r'^[\s,>+~]*$',
          ).hasMatch(selector.replaceAll(RegExp(r':where\([^)]*\)'), '')))
            selector,
      ];
      expect(
        offenders,
        isEmpty,
        reason:
            'a reset selector outside :where() outranks component utilities '
            'and silently erases their chrome',
      );
    });

    test('every preview pane pairs preview-content with not-content', () {
      final emitters = {
        'docs_site/lib/components/live_preview.dart': livePreviewSource,
        'docs_core/lib/embed/embed_page.dart': File(
          '../docs_core/lib/embed/embed_page.dart',
        ).readAsStringSync(),
      };
      final offenders = <String>[];
      for (final MapEntry(key: path, value: source) in emitters.entries) {
        final matches = RegExp("'preview-content[^']*'").allMatches(source);
        expect(matches, isNotEmpty, reason: '$path no longer emits preview-content');
        for (final match in matches) {
          if (!match.group(0)!.contains('not-content')) {
            offenders.add('$path: ${match.group(0)}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'a preview pane without not-content lets jaspr_content prose rules '
            'back in, and they outrank the zero-specificity reset',
      );
    });
  });
}
