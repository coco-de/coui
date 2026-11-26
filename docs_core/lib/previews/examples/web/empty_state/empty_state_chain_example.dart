import 'package:coui_web/coui_web.dart';

/// T3 저작 규약 형태의 chain 예제 — `withStyle` full-control 한 인스턴스.
///
/// The redesign drops the bordered/filled panel `EmptyState` used to
/// draw, so it no longer has a `borderRadius` / `backgroundColor` field
/// for a token-precise getter to name — the chain surface is
/// `withStyle` only now (T1 → T3).
class EmptyStateChainExample extends StatefulComponent {
  const EmptyStateChainExample({super.key});

  @override
  State<EmptyStateChainExample> createState() => _EmptyStateChainExampleState();
}

class _EmptyStateChainExampleState extends State<EmptyStateChainExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    ).withStyle(
      const CoreEmptyStateStyle(
        minHeight: 200,
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
          vertical: CoreSpace.space8,
        ),
      ),
    );
  }
}
