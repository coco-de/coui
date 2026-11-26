/// Hover 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="hover/...">` 가 읽는다. 같은 이름의 Web 파일(`hover_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 효과는 포인터가 있어야 보이므로 정지 화면으로 보일 장면이 없다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'hover_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _hover;

/// 장면 이름(`hover/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {};

Widget _hover(Map<String, String> props, String? label) {
  final effect = page.demoEffectOf(props);
  if (page.demoReportsHover(props)) return _HoverReport(effect: effect);
  return Hover(effect: effect, child: _card(effect, label ?? page.demoLabel));
}

/// `Hover` 로 감싸는 카드.
Widget _card(CoreHoverEffect effect, String text) => Card(
  variant: CoreCardVariant.outlined,
  cardStyle: page.demoCardStyleOf(effect),
  child: Text(text),
);

/// `onHover` 가 알려 준 값을 카드의 글자로 보인다.
class _HoverReport extends StatefulWidget {
  const _HoverReport({required this.effect});

  final CoreHoverEffect effect;

  @override
  State<_HoverReport> createState() => _HoverReportState();
}

class _HoverReportState extends State<_HoverReport> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Hover(
    effect: widget.effect,
    onHover: (hovered) => setState(() => _hovered = hovered),
    child: _card(widget.effect, _hovered ? page.demoReportOn : page.demoReportOff),
  );
}
