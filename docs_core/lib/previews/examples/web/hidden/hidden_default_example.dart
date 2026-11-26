import 'package:coui_web/coui_web.dart';

class HiddenDefaultExample extends StatefulComponent {
  const HiddenDefaultExample({super.key});

  @override
  State<HiddenDefaultExample> createState() => _HiddenDefaultExampleState();
}

class _HiddenDefaultExampleState extends State<HiddenDefaultExample> {
  bool _hidden = false;

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () => setState(() => _hidden = !_hidden),
          child: Text(_hidden ? '보기' : '숨기기'),
        ),
        Gap.space12(),
        Hidden(
          hidden: _hidden,
          child: div(
            [
              div(
                [Text('켜고 끌 수 있는 내용')],
                classes: 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}',
              ),
            ],
            classes: 'bg-${cs.surfaceContainer} rounded-${CoreRadius.scale.radius16} p-${CoreSpace.scale.space16}',
          ),
        ),
      ],
      classes: 'inline-flex flex-col items-start',
    );
  }
}
