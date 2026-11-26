import 'package:coui_web/coui_web.dart';

/// No-icon Toast example for docs_site Web preview.
///
/// `showIcon: false` leaves the variant's glyph and the gap after it out, so
/// the message and description start at the panel's inset. The three variants
/// differ only by that glyph, which makes a toast without it the same slab
/// whichever variant it carries.
class ToastNoIconExample extends StatelessComponent {
  const ToastNoIconExample({super.key});

  @override
  Component build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      variant: CoreToastVariant.success,
      showIcon: false,
      onDismiss: () {},
    );
  }
}
