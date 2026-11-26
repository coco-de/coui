import 'package:coui_web/coui_web.dart';

/// Text.rich — TextSpan tree with mixed inline styles.
class TextRichExample extends StatelessComponent {
  const TextRichExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return div(
      classes: 'p-${CoreSpace.scale.space16}',
      [
        Text.rich(
          TextSpan(
            text: '섞어 쓰기: ',
            children: [
              TextSpan(
                text: '기본색 ',
                style: TextStyle(
                  color: '${cs.primary}',
                  fontWeight: CoreFontWeight.scale.semibold,
                ),
              ),
              const TextSpan(text: '+ '),
              TextSpan(
                text: '기울인 오류색',
                style: TextStyle(
                  color: '${cs.error}',
                  fontStyle: FontStyle.italic,
                ),
              ),
              const TextSpan(text: ' + '),
              const TextSpan(
                text: '밑줄',
                style: TextStyle(decoration: CoreTextDecoration.underline),
              ),
            ],
          ),
        ).bodyMedium,
      ],
    );
  }
}
