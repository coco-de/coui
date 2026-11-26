import 'package:coui_web/coui_web.dart';

/// Inline Alert example for docs_site Web preview.
///
/// A one-line status strip: a badge takes the tone glyph's place through the
/// `leading` slot, the title is the only line, and the caller's chevron sits
/// in the `action` slot.
class AlertInlineExample extends StatelessComponent {
  const AlertInlineExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Alert(
      layout: CoreAlertLayout.inline,
      leading: Badge(
        tone: CoreBadgeTone.success,
        showDot: true,
        child: Text('동기화됨'),
      ),
      title: '모든 변경 사항을 클라우드에 저장했어요.',
      action: Icon(
        LucideIcons.chevronDown,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size16,
          color: CoreColor.token(CoreColors.onSurfaceSubtle),
        ),
      ),
    );
  }
}
