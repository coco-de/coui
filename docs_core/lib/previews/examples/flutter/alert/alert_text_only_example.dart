import 'package:coui_flutter/coui_flutter.dart';

/// Text-only Alert example for docs_site Flutter preview.
///
/// No glyph (`showIcon: false`) — the notice reads by its words and its
/// tone. The tone reaches the title through the theme's `variantStyles`, so
/// a product that speaks this way states it once for every alert of a tone
/// rather than on each one.
class AlertTextOnlyExample extends StatelessWidget {
  const AlertTextOnlyExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        coreComponentTheme: () => const CoreComponentTheme(
          alert: CoreAlertTheme(
            variantStyles: {
              CoreAlertVariant.success: CoreAlertStyle(
                titleColor: CoreColor.token(CoreColors.onSuccessContainer),
              ),
              CoreAlertVariant.warning: CoreAlertStyle(
                titleColor: CoreColor.token(CoreColors.onWarningContainer),
              ),
            },
          ),
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Alert.success(
            title: '송금 완료',
            description: '10분 안에 입금돼요.',
            showIcon: false,
          ),
          Gap.space12(),
          Alert.warning(
            title: '오후 4시에 환율이 바뀌어요',
            description: '그 전에 보내면 지금 환율이 적용돼요.',
            showIcon: false,
          ),
        ],
      ),
    );
  }
}
