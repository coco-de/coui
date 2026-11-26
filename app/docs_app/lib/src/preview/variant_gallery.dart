/// 변형 갤러리 — jaspr 의 `.variant-gallery` 를 네이티브로 옮긴 것.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/preview/chain_shuffle_control.dart';
import 'package:docs_app/src/preview/live_preview.dart';
import 'package:docs_core/shared/chain_tier1.dart';
import 'package:docs_core/shared/preview_layout.dart';

/// chain 패널 인스턴스 카운터 — jaspr SSG 의 top-level 카운터와 같은 역할.
/// State 가 initState 에서 한 번 소비하므로 rebuild 로는 늘지 않는다.
/// `app` 세그먼트는 진단용 표기일 뿐이다 — 사이트와는 힙이 달라 충돌
/// 대상 자체가 없다.
int _chainPanelCounter = 0;

/// 갤러리 그리드의 열 최소 너비 (`minmax(300px, 1fr)`).
const _kGalleryColumnMinWidth = 300.0;

/// 한 컴포넌트의 여러 변형을 각각 라벨 붙인 [DocsLivePreview] 로 나열한다.
///
/// 항목을 한 줄에 하나씩 놓을지와, 각 항목 **안에서** 두 페인을 쌓을지는
/// **서로 다른 두 결정**이다:
/// - 항목 한 줄에 하나 → 두 셋의 **합집합**
/// - 페인 쌓기 → `kDocsWideComponents` **만** ([DocsLivePreview] 가 판단)
///
/// 그래서 full-row 컴포넌트는 Web | Flutter 를 나란히 둔 채로 단일 프리뷰와
/// 같은 너비를 받는다.
///
/// `chain` 변형은 이 두 결정 밖에 있다 — 메타데이터로 자동 합성돼(md 편집
/// 없이) 122개 컴포넌트에 동시에 붙으므로, "진짜" 변형들과 auto-fit 컬럼을
/// 다투면 138개 문서 페이지 대다수의 프리뷰 폭이 chain 유무에 따라
/// 흔들린다. 그래서 chain 은 auto-fit 계산(`_GalleryGrid`)과 fullRow 나열
/// 어느 쪽에도 끼지 않고, 항상 자기 행 전체를 쓰는 별도 항목으로 맨 뒤에
/// 붙는다 — Web 의 `.variant-gallery-item--chain { grid-column: 1 / -1 }`
/// 과 같은 결정.
class DocsVariantGallery extends StatelessWidget {
  /// [component] 의 [variants] 를 나열하는 갤러리를 만든다.
  const DocsVariantGallery({
    required this.component,
    required this.variants,
    super.key,
  });

  /// 프리뷰할 컴포넌트 슬러그 (예: `button`).
  final String component;

  /// 나열할 변형 이름들 (예: `['primary', 'secondary']`).
  final List<String> variants;

  @override
  Widget build(BuildContext context) {
    final fullRow =
        kDocsWideComponents.contains(component) ||
        kDocsFullRowGalleryComponents.contains(component);
    final hasChain = variants.contains('chain');
    final nonChainVariants = [
      for (final variant in variants)
        if (variant != 'chain') variant,
    ];

    return Padding(
      // `.variant-gallery { margin: 1.5rem 0 }`.
      padding: const .symmetric(vertical: CoreSpace.space24),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          if (nonChainVariants.isNotEmpty)
            fullRow
                ? Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .stretch,
                    children: [
                      for (final variant in nonChainVariants)
                        _GalleryItem(component: component, variant: variant),
                    ],
                  )
                : _GalleryGrid(
                    component: component,
                    variants: nonChainVariants,
                  ),
          if (hasChain) _GalleryItem(component: component, variant: 'chain'),
        ],
      ),
    );
  }
}

/// `repeat(auto-fit, minmax(300px, 1fr))` 의 네이티브 대응.
///
/// 가용 너비에 300px 열이 몇 개 들어가는지 센 뒤 `variants.length` 로
/// clamp 한다 — 즉 아이템이 없는 트랙은 CSS `auto-fit` 처럼 완전히 접혀
/// 남는 폭이 실제 아이템에게 재분배된다. `auto-fill` 이었다면 아이템 없는
/// 트랙도 자리만 예약한 채 남아, variant 가 1개뿐인 갤러리의 그 하나가
/// 전체 폭이 아니라 트랙 1개 폭에 머물렀을 것이다.
class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({required this.component, required this.variants});

  final String component;
  final List<String> variants;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = CoreSpace.space16;
        final width = constraints.maxWidth;
        // 열 n 개가 들어가려면 n*min + (n-1)*gap <= width.
        final columns = ((width + gap) / (_kGalleryColumnMinWidth + gap))
            .floor()
            .clamp(1, variants.length);
        final itemWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final variant in variants)
              SizedBox(
                width: itemWidth,
                child: _GalleryItem(component: component, variant: variant),
              ),
          ],
        );
      },
    );
  }
}

/// 라벨 + 프리뷰 한 쌍 (`.variant-gallery-item`).
///
/// Stateful 인 이유는 chain 항목의 panelId 하나 — 스토어 키·셔플 컨트롤·
/// 프리뷰가 공유하는 인스턴스-유일 id 라 rebuild 마다 새로 뽑으면 안 된다
/// (initState 1회 발급).
class _GalleryItem extends StatefulWidget {
  const _GalleryItem({required this.component, required this.variant});

  final String component;
  final String variant;

  @override
  State<_GalleryItem> createState() => _GalleryItemState();
}

class _GalleryItemState extends State<_GalleryItem> {
  /// chain 항목의 인스턴스-유일 id — non-chain 은 null (기존 렌더 무변경).
  String? _panelId;

  @override
  void initState() {
    super.initState();
    if (widget.variant == 'chain') {
      _panelId = 'chain-${widget.component}-app-${++_chainPanelCounter}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 셔플 affordance 는 T1(양축 getter 보유) 만 — jaspr 쪽과 같은
    // server-safe name-set 판정 (`kChainTier1Components`).
    final panelId = _panelId;
    final showShuffle =
        panelId != null && kChainTier1Components.contains(widget.component);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        // 라벨과 프리뷰 사이 간격은 [DocsLivePreview] 자신의 세로 여백이
        // 낸다. jaspr 도 결과가 같다 — 라벨의 `margin-bottom: 0.5rem` 과
        // 프리뷰의 `margin-top: 1.5rem` 이 인접 형제라 collapse 되어 큰
        // 쪽(1.5rem)만 남는다. 여기에 8px 을 더 넣으면 오히려 어긋난다.
        if (showShuffle)
          // chain 항목은 라벨 행이 칩·셔플 버튼을 담는 행으로 확장된다 —
          // jaspr 의 `.variant-gallery-label--chain` 과 같은 배치.
          Row(
            children: [
              Text(
                _capitalize(widget.variant),
              ).labelMedium.semiBold.onSurfaceVariant,
              const Spacer(),
              DocsChainShuffleControl(panelId: panelId),
            ],
          )
        else
          Text(
            _capitalize(widget.variant),
          ).labelMedium.semiBold.onSurfaceVariant,
        DocsLivePreview(
          component: widget.component,
          variant: widget.variant,
          panelId: panelId,
        ),
      ],
    );
  }
}

/// `text-transform: capitalize` 의 대응 — 각 단어의 첫 글자만 대문자로.
String _capitalize(String value) {
  return value
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
