/// chain 패널의 랜덤 순열 토글 — jaspr `ChainShuffleControl` 의 네이티브
/// 쌍둥이 (갤러리 라벨 행 배치).
library;

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/chain_shuffle_store.dart';
import 'package:flutter/semantics.dart' show SemanticsService;

/// SR 통보 debounce — 연타 시 통보 큐가 밀리지 않게 마지막 좌표만 알린다
/// (jaspr 쪽 `aria-live` debounce 와 같은 값).
const _kAnnounceDebounce = Duration(milliseconds: 300);

/// 순열 칩 + Shuffle 버튼.
///
/// jaspr 쪽과 역할 분담이 다르다 — 사이트 컨트롤은 코드 패널 DOM 까지 직접
/// 치환하지만, 네이티브는 코드/페인 갱신이 전부 `DocsLivePreview` 의
/// 스토어
/// 구독으로 흐르므로 이 위젯은 **advance + 칩 표시 + SR 통보**만 한다.
/// 상태의 단일 출처는 같은 [chainShuffleStore] 다.
class DocsChainShuffleControl extends StatefulWidget {
  /// [panelId] 패널의 셔플 컨트롤을 만든다.
  const DocsChainShuffleControl({required this.panelId, super.key});

  /// 갤러리가 부여한 인스턴스-유일 chain 패널 id — 스토어 키.
  final String panelId;

  @override
  State<DocsChainShuffleControl> createState() =>
      _DocsChainShuffleControlState();
}

class _DocsChainShuffleControlState extends State<DocsChainShuffleControl> {
  Timer? _announceTimer;

  @override
  void dispose() {
    _announceTimer?.cancel();
    super.dispose();
  }

  String get _chipText => chainPermutationLabel(
    chainPermutationAt(chainShuffleStore.stepOf(widget.panelId)),
  );

  void handleShuffle() {
    chainShuffleStore.advance(widget.panelId);
    // 칩은 즉시, SR 통보는 debounce 로 최종 좌표만 — 상태 변경이지 실패가
    // 아니므로 polite (jaspr 쪽 `aria-live="polite"` 와 동일 판정).
    setState(() {});
    _announceTimer?.cancel();
    _announceTimer = Timer(_kAnnounceDebounce, () {
      if (!mounted) return;
      // polite 가 기본값이다 — 상태 변경이지 실패가 아니므로 그대로 둔다
      // (jaspr 쪽 `aria-live="polite"` 와 동일 판정).
      unawaited(SemanticsService.announce(_chipText, TextDirection.ltr));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        // 재현 좌표 표기 — 실재 getter 이름 그대로 (jaspr 칩과 같은 단일
        // 출처 `chainPermutationLabel`, 표기 왜곡 금지).
        Text(_chipText).labelSmall.mono.onSurfaceVariant,
        const Gap.space8(),
        Button(
          variant: .outline,
          size: .xs,
          onPressed: handleShuffle,
          // 라벨이 곧 accessible name — 보이는 것과 들리는 것이 같다
          // (jaspr 쪽 aria-label = visible text 판정과 동일). 아이콘은 장식.
          leading: const Icon(LucideIcons.shuffle),
          child: const Text('Shuffle'),
        ),
      ],
    );
  }
}
