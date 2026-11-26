import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreMenuStyle] slot without constructing the component
/// from scratch.
class MenuChainExample extends StatelessComponent {
  const MenuChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Menu(
      ariaLabel: '주 메뉴',
      items: [
        const CoreMenuItem.label('탐색'),
        CoreMenuItem.action('홈', onPressed: () {}, active: true),
        CoreMenuItem.action('프로필', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.checkbox('격자 보기', onChanged: (_) {}, checked: true),
        CoreMenuItem.action('설정', disabled: true),
      ],
    ).withStyle(
      const CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          markIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.tertiary),
          ),
        ),
        dividerStyle: CoreDividerStyle(
          color: CoreColor.token(CoreColors.primary),
          thickness: CoreStrokeWidth.stroke2,
        ),
      ),
    );
  }
}
