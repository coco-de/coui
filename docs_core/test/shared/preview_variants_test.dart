import 'package:test/test.dart';

import 'package:docs_core/previews/flutter_code_registry.dart';
import 'package:docs_core/shared/preview_variants.dart';

void main() {
  group('docsComponentHasChainPreview', () {
    test('registry-derived: chain snippet differs from default', () {
      // `command` ships a dedicated chain snippet (added with the
      // withStyle chain sugar) — the registry is the single source.
      expect(docsComponentHasChainPreview('command'), isTrue);
    });

    test('unknown component has no chain preview', () {
      expect(docsComponentHasChainPreview('no-such-component'), isFalse);
    });
  });

  group('resolveDocsPreviewVariants', () {
    test('hidden: md-declared variants pass through unchanged', () {
      expect(
        resolveDocsPreviewVariants(
          'command',
          const [],
          chainMode: DocsChainPreviewMode.hidden,
        ),
        isEmpty,
      );
      expect(
        resolveDocsPreviewVariants(
          'button',
          const ['primary', 'secondary'],
          chainMode: DocsChainPreviewMode.hidden,
        ),
        equals(const ['primary', 'secondary']),
      );
    });

    test('appended: appends chain after declared variants', () {
      expect(
        resolveDocsPreviewVariants(
          'button',
          const ['primary', 'secondary'],
          chainMode: DocsChainPreviewMode.appended,
        ),
        equals(const ['primary', 'secondary', 'chain']),
      );
    });

    test('appended: bare preview becomes default + chain (default first)', () {
      expect(
        resolveDocsPreviewVariants(
          'command',
          const [],
          chainMode: DocsChainPreviewMode.appended,
        ),
        equals(const ['default', 'chain']),
      );
    });

    test('appended: no chain snippet → declared unchanged', () {
      expect(
        resolveDocsPreviewVariants(
          'no-such-component',
          const [],
          chainMode: DocsChainPreviewMode.appended,
        ),
        isEmpty,
      );
    });

    test('appended: never duplicates an already-declared chain', () {
      expect(
        resolveDocsPreviewVariants(
          'command',
          const ['chain'],
          chainMode: DocsChainPreviewMode.appended,
        ),
        equals(const ['chain']),
      );
    });

    test('only: replaces the declared list with chain alone', () {
      expect(
        resolveDocsPreviewVariants(
          'button',
          const ['primary', 'secondary'],
          chainMode: DocsChainPreviewMode.only,
        ),
        equals(const ['chain']),
      );
      expect(
        resolveDocsPreviewVariants(
          'command',
          const [],
          chainMode: DocsChainPreviewMode.only,
        ),
        equals(const ['chain']),
      );
    });

    test('only: no chain snippet → declared unchanged', () {
      expect(
        resolveDocsPreviewVariants(
          'no-such-component',
          const ['a', 'b'],
          chainMode: DocsChainPreviewMode.only,
        ),
        equals(const ['a', 'b']),
      );
    });

    test(
      'production mode appends the chain gallery to every capable preview',
      () {
        // 출하 모드 = `appended` — 139개 md 를 편집하지 않고 chain 스니펫을
        // 가진 모든 컴포넌트 프리뷰 뒤에 chain 갤러리가 자동 노출된다.
        expect(kDocsChainPreviewMode, DocsChainPreviewMode.appended);
        expect(
          resolveDocsPreviewVariants('command', const []),
          equals(const ['default', 'chain']),
        );
      },
    );

    group('chain="off" 저자 큐레이션', () {
      test('opt-out 태그는 어느 모드에서도 선언 그대로다', () {
        for (final mode in DocsChainPreviewMode.values) {
          expect(
            resolveDocsPreviewVariants(
              'command',
              const ['default'],
              chainOptOut: true,
              chainMode: mode,
            ),
            equals(const ['default']),
            reason: '$mode 에서 opt-out 이 무시됐다',
          );
        }
      });

      test('opt-out 은 태그 스코프 — 다른 태그의 append 에 무영향', () {
        // 같은 페이지의 다른 태그는 각자 resolve 되므로, off 가 아닌
        // 태그는 여전히 chain 을 받는다 (페이지당 chain ≥1 의 근거).
        expect(
          resolveDocsPreviewVariants('command', const []),
          contains('chain'),
        );
      });
    });
  });

  group('registry chain coverage', () {
    test('every chain-capable builder returns a non-empty chain snippet', () {
      for (final entry in kFlutterCodeSnippetRegistry.entries) {
        if (!docsComponentHasChainPreview(entry.key)) continue;
        expect(
          entry.value('chain').trim(),
          isNotEmpty,
          reason: '${entry.key} chain snippet is empty',
        );
      }
    });
  });
}
