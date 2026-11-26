import 'package:coui_flutter/coui_flutter.dart';

/// Text.rich — TextSpan tree with mixed inline styles.
class TextRichExample extends StatelessWidget {
  const TextRichExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ts = theme.typography;
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Text.rich(
        TextSpan(
          text: '섞어 쓰기: ',
          children: [
            TextSpan(
              text: '기본색 ',
              style: TextStyle(
                color: cs.primary.toValue(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: '+ '),
            TextSpan(
              text: '기울인 오류색',
              style: TextStyle(
                color: cs.error.toValue(),
                fontStyle: FontStyle.italic,
              ),
            ),
            const TextSpan(text: ' + '),
            const TextSpan(
              text: '밑줄',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ],
        ),
        style: ts.bodyMedium.toValue(theme: Theme.of(context)),
      ),
    );
  }
}
