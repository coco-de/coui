import 'package:coui_flutter/coui_flutter.dart';

class DisclosureChainExample extends StatelessWidget {
  const DisclosureChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Disclosure(
      title: 'CoUI는 무엇인가요?',
      open: true,
      content: Text(
        'Flutter와 웹에서 똑같이 보이는 디자인 시스템이에요.',
      ),
    ).withStyle(
      const CoreDisclosureStyle(
        contentInset: CoreEdgeInsets.all(CoreSpace.space24),
        triggerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
        iconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
