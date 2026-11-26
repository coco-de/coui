import 'package:coui_flutter/coui_flutter.dart';

/// Wrap-related parameters — overflow / maxLines / textAlign.
class TextWrapExample extends StatelessWidget {
  const TextWrapExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Theme.of(context).geometry.space(CoreSpace.space24),
        children: [
          _section(context, 'overflow / maxLines', [
            const Text(
              '컨테이너 폭을 넘으면 말줄임표로 잘려야 하는 긴 문장이에요. '
              '다람쥐 헌 쳇바퀴에 타고파, 다람쥐 헌 쳇바퀴에 타고파, '
              '말줄임표가 보일 때까지 같은 문장을 되풀이해요.',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: CoreFontSize.s14),
            ),
            const Text(
              'maxLines 2 로 줄 수를 제한한 긴 문장이에요. 다람쥐 헌 쳇바퀴에 타고파, '
              '다람쥐 헌 쳇바퀴에 타고파, 둘째 줄에서 줄 수 제한이 걸리면 '
              '말줄임표로 잘려요.',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(fontSize: CoreFontSize.s14),
            ),
          ]),
          _section(context, 'textAlign', [
            const Text(
              '가운데 정렬',
              textAlign: TextAlign.center,
            ).bodyMedium,
            const Text(
              '끝 정렬',
              textAlign: TextAlign.end,
            ).bodyMedium,
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Theme.of(context).geometry.space(CoreSpace.space8),
      children: [
        Text(title).titleSmall.semiBold.onSurfaceVariant,
        ...children,
      ],
    );
  }
}
