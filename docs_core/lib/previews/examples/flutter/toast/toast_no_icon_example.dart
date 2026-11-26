import 'package:coui_flutter/coui_flutter.dart';

/// No-icon Toast example for docs_site Flutter preview.
///
/// `showIcon: false` leaves the variant's glyph and the gap after it out, so
/// the message and description start at the panel's inset. The three variants
/// differ only by that glyph, which makes a toast without it the same slab
/// whichever variant it carries.
class ToastNoIconExample extends StatelessWidget {
  const ToastNoIconExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      variant: CoreToastVariant.success,
      showIcon: false,
      onDismiss: () {},
    );
  }
}
