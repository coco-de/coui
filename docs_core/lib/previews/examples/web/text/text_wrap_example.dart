import 'package:coui_web/coui_web.dart';

/// Wrap-related parameters — overflow / maxLines / textAlign.
class TextWrapExample extends StatelessComponent {
  const TextWrapExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col w-full gap-${CoreSpace.scale.space24} p-${CoreSpace.scale.space16}',
      [
        _section('overflow / maxLines', [
          Text(
            '컨테이너 폭을 넘으면 말줄임표로 잘려야 하는 긴 문장이에요. '
            '다람쥐 헌 쳇바퀴에 타고파, 다람쥐 헌 쳇바퀴에 타고파, '
            '말줄임표가 보일 때까지 같은 문장을 되풀이해요.',
            overflow: CoreTextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontSize: CoreFontSize.s14),
          ),
          Text(
            'maxLines 2 로 줄 수를 제한한 긴 문장이에요. 다람쥐 헌 쳇바퀴에 타고파, '
            '다람쥐 헌 쳇바퀴에 타고파, 둘째 줄에서 줄 수 제한이 걸리면 '
            '말줄임표로 잘려요.',
            overflow: CoreTextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(fontSize: CoreFontSize.s14),
          ),
        ]),
        _section('textAlign', [
          Text('가운데 정렬', textAlign: CoreTextAlign.center).bodyMedium,
          Text('끝 정렬', textAlign: CoreTextAlign.end).bodyMedium,
        ]),
      ],
    );
  }

  Component _section(String title, List<Component> children) {
    return div(
      classes: 'flex flex-col w-full gap-${CoreSpace.scale.space8}',
      [
        Text(title).titleSmall.semiBold.onSurfaceVariant,
        ...children,
      ],
    );
  }
}
