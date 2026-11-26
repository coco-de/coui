import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/chain_shuffle_store.dart';
import 'package:docs_core/shared/preview_panel_id.dart';

import 'chain_code_dom.dart';

/// SR 통보 debounce — 연타 시 aria-live 큐가 밀리지 않게 마지막 좌표만
/// 통보한다.
const _kAnnounceDebounce = Duration(milliseconds: 300);

/// chain 패널의 랜덤 순열 토글 — `@client` 아일랜드, 갤러리 라벨 행 배치.
///
/// 세 조각으로 구성된다: **순열 칩**(현재 좌표 `.radius16.primary` 표기 —
/// monospace, 재현 좌표이므로 표기 왜곡 금지) · **⤨ Shuffle 버튼**
/// (aria-label 은 visible text 와 동일 문자열 — accessible name 을
/// 대체하므로 다른 문자열이면 보이는 것과 들리는 것이 갈라진다) ·
/// **visually-hidden `aria-live="polite"` 리전**(debounce 후 현재 좌표
/// 통보 — 상태 변경이지 실패가 아니므로 assertive 금지).
///
/// 클릭 1회 = 스토어 step 1 전진. 같은 Dart 힙의 [chainShuffleStore] 를
/// Web 팬(`WebPreview`)·Flutter 팬(`PreviewApp`)이 구독하고 있어 두 팬은
/// 리스너로 갱신되고, 코드 패널(양 탭)과 copy `data-code` 는 이 아일랜드가
/// base 스니펫 위 getter-토큰 치환으로 직접 갱신한다 — copy 는 **활성 탭
/// 추종**(기존 탭 전환 스크립트가 `data-code` 를 활성 패널 텍스트로
/// 재설정하므로, 셔플도 지금 보이는 탭의 새 코드를 기록해야 둘이 안
/// 갈라진다).
///
/// base 스니펫은 첫 클릭 전 DOM(SSG 산출물)에서 1회 캡처한다 — 치환은
/// 항상 pristine base 에 적용되므로 누적 오염이 없다.
@client
class ChainShuffleControl extends StatelessComponent {
  const ChainShuffleControl({required this.panelId, required this.component, super.key});

  final String panelId;
  final String component;

  @override
  Component build(BuildContext context) => ChainShuffleContent(panelId: panelId, component: component);
}

/// Shuffle behavior composed into a parent island without a second boundary.
class ChainShuffleContent extends StatefulComponent {
  const ChainShuffleContent({
    required this.panelId,
    required this.component,
    super.key,
  });

  /// SSG 가 부여한 인스턴스-유일 chain 패널 id — 스토어 키.
  final String panelId;

  /// 컴포넌트 slug (진단용).
  final String component;

  @override
  State<ChainShuffleContent> createState() => _ChainShuffleControlState();
}

class _ChainShuffleControlState extends State<ChainShuffleContent> {
  /// 첫 클릭 전 DOM 에서 캡처한 pristine base 스니펫 (탭별).
  String? _baseWebCode;
  String? _baseFlutterCode;

  Timer? _announceTimer;
  String _announced = '';

  @override
  void initState() {
    super.initState();
    // 순열 딥링크 복원 — URL 쿼리(`?{panelId}={step}`)가 있으면 그 좌표로
    // 시작한다. 서버 경로에서는 readQueryParam 이 null(스텁)이라 SSG 는
    // 언제나 base 를 그린다 (스토어 read-only 계약 그대로).
    final deepLinked = int.tryParse(readQueryParam(component.panelId) ?? '');
    if (deepLinked != null && deepLinked > 0) {
      chainShuffleStore.restore(component.panelId, deepLinked);
      // 페인은 스토어 통지/자기 build 로 따라오지만 코드 패널·copy 는 DOM
      // 치환이라 여기서 셔플과 같은 경로로 갱신한다. 통보는 안 한다 —
      // 사용자 액션이 아니라 페이지 로드다.
      context.binding.addPostFrameCallback(() {
        if (mounted) _applyCodeSurfaces(_current);
      });
    }
  }

  @override
  void dispose() {
    _announceTimer?.cancel();
    super.dispose();
  }

  ChainPermutation get _current => chainPermutationAt(chainShuffleStore.stepOf(component.panelId));

  /// 칩·SR 통보가 공유하는 좌표 표기 — 네이티브 컨트롤과 같은 단일 출처
  /// (`chainPermutationLabel`, 표기 사본 금지).
  String get _chipText => chainPermutationLabel(_current);

  /// 코드 패널(양 탭)과 copy `data-code` 를 [permutation] 의 치환 결과로
  /// 갱신한다 — 셔플 클릭과 딥링크 복원이 공유하는 경로.
  void _applyCodeSurfaces(ChainPermutation permutation) {
    // 캡처는 최초 1회 — 이후 DOM 은 치환 결과라 base 가 아니다.
    _baseWebCode ??= readElementText(
      chainCodeElementId(component.panelId, forFlutter: false),
    );
    _baseFlutterCode ??= readElementText(
      chainCodeElementId(component.panelId, forFlutter: true),
    );

    final webCode = _baseWebCode;
    final flutterCode = _baseFlutterCode;
    final substitutedWeb = webCode != null ? substituteChainTokens(webCode, permutation) : null;
    final substitutedFlutter = flutterCode != null ? substituteChainTokens(flutterCode, permutation) : null;

    if (substitutedWeb != null) {
      writeElementText(
        chainCodeElementId(component.panelId, forFlutter: false),
        substitutedWeb,
      );
    }
    if (substitutedFlutter != null) {
      writeElementText(
        chainCodeElementId(component.panelId, forFlutter: true),
        substitutedFlutter,
      );
    }

    // copy 는 활성 탭의 새 순열 코드 — 지금 보이는 코드와 복사물이 같아야
    // 한다.
    final copyId = chainCopyElementId(component.panelId);
    final active = activeCodeTab(copyId);
    final copyCode = active == 'flutter' ? substitutedFlutter : substitutedWeb;
    if (copyCode != null) {
      setElementAttribute(copyId, 'data-code', copyCode);
    }
  }

  void handleShuffle() {
    chainShuffleStore.advance(component.panelId);
    _applyCodeSurfaces(_current);

    // 순열 딥링크 — URL 이 항상 현재 좌표를 담는다 (공유·버그 재현).
    // 순환 한 바퀴를 돌아 base 로 복귀하면 파라미터를 지워 URL 을 원상태로.
    final normalized = chainShuffleStore.stepOf(component.panelId) % kChainPermutationCount;
    writeQueryParam(component.panelId, normalized == 0 ? null : '$normalized');

    // 칩은 즉시, SR 통보는 debounce 로 최종 좌표만.
    setState(() {});
    _announceTimer?.cancel();
    _announceTimer = Timer(_kAnnounceDebounce, () {
      setState(() => _announced = _chipText);
    });
  }

  @override
  Component build(BuildContext context) {
    return span(classes: 'chain-shuffle-control', [
      span(classes: 'chain-permutation-chip', [Component.text(_chipText)]),
      button(
        classes: 'chain-shuffle-btn',
        attributes: {
          'type': 'button',
          // visible text 와 동일 문자열 — aria-label 은 accessible name 을
          // 대체하므로 다른 문자열이면 화면과 낭독이 갈라진다 (아이콘
          // 글리프는 낭독에서 빠지는 게 의도).
          'aria-label': 'Shuffle',
          'data-chain-panel': component.panelId,
        },
        events: {'click': (_) => handleShuffle()},
        [
          span(
            attributes: const {'aria-hidden': 'true'},
            [
              Component.text('⤨ '),
            ],
          ),
          Component.text('Shuffle'),
        ],
      ),
      span(
        classes: 'chain-sr-only',
        attributes: const {'aria-live': 'polite'},
        [Component.text(_announced)],
      ),
    ]);
  }
}
