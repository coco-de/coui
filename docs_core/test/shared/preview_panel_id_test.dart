@TestOn('vm')
library;

import 'package:docs_core/shared/preview_panel_id.dart';
import 'package:test/test.dart';

/// id 파생식 단일 출처의 계약을 고정한다 — 임베드 생성·높이 적용 JS·
/// 코드 패널 접근이 전부 같은 함수를 부르므로, 파생식이 바뀌면 여기가
/// 먼저 깨져야 한다 (호출부 간 어긋남은 런타임에서 "높이 미적용 /
/// 코드 미갱신" 으로 늦게 드러난다).
void main() {
  test('non-chain: 기존 component-variant 파생 유지', () {
    expect(
      flutterEmbedElementId(component: 'button', variant: 'primary'),
      'flutter-button-primary',
    );
    expect(
      flutterEmbedElementId(component: 'button'),
      'flutter-button-default',
    );
    expect(
      webPreviewElementId(component: 'button', variant: 'primary'),
      'web-button-primary',
    );
  });

  test('chain: panelId 파생 — 같은 컴포넌트 복수 패널에서도 유일', () {
    expect(
      flutterEmbedElementId(
        component: 'button',
        variant: 'chain',
        panelId: 'chain-button-1',
      ),
      'flutter-chain-button-1',
    );
    expect(
      webPreviewElementId(
        component: 'button',
        variant: 'chain',
        panelId: 'chain-button-2',
      ),
      'web-chain-button-2',
    );
  });

  test('코드 요소·copy 버튼 id 파생', () {
    expect(
      chainCodeElementId('chain-button-1', forFlutter: false),
      'code-web-chain-button-1',
    );
    expect(
      chainCodeElementId('chain-button-1', forFlutter: true),
      'code-flutter-chain-button-1',
    );
    expect(chainCopyElementId('chain-button-1'), 'copy-chain-button-1');
  });
}
