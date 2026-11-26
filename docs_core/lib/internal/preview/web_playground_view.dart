import 'package:coui_web/coui_web.dart';
import '../../previews/props/web_prop_previews.dart';
import '../../shared/docs_locale.dart';
import '../../shared/playground_spec.dart';
import 'selection.dart';
import 'web_selection.dart';
import 'web_stage.dart';

enum DocsPlaygroundPlatform {
  web('Jaspr Web'),
  flutter('Flutter'),
  both('나란히');

  const DocsPlaygroundPlatform(this.label);

  /// 토글에 적는 이름.
  final String label;
}

Component buildWebPlaygroundView({
  required String componentName,
  required DocsPlaygroundSpec spec,
  required Map<String, String> props,
  required DocsPlaygroundPlatform platform,
  required bool showWeb,
  required bool showFlutter,
  required Component? flutterContent,
  required Component codeView,
  required void Function(Map<String, String>) onSetProps,
  required void Function(DocsPlaygroundPlatform) onSetPlatform,
}) {
  final webBuilder = kWebPropPreviews[componentName];
  // 컨트롤이 없는 플레이그라운드(바꿔 볼 속성이 없는 컴포넌트)는 컨트롤 열을
  // 그리지 않는다 — 열이 있으면 테두리 친 빈 칸이 무대 옆에 남는다.
  final hasControls = spec.controls.isNotEmpty;
  return div(classes: 'docs-playground-inner', [
    div(classes: hasControls ? 'docs-playground-main' : 'docs-playground-main is-bare', [
      div(classes: 'docs-playground-stage', [
        div(classes: 'docs-playground-platforms', [
          ToggleGroup<DocsPlaygroundPlatform>(
            size: CoreComponentSize.sm,
            value: platform,
            onChanged: onSetPlatform,
            items: [
              for (final platform in DocsPlaygroundPlatform.values)
                CoreToggleGroupItem(value: platform, label: platform.label),
            ],
          ),
        ]),
        div(classes: 'docs-playground-panes${platform == DocsPlaygroundPlatform.both ? ' is-both' : ''}', [
          buildWebPlaygroundPane(
            webBuilder == null
                ? null
                : renderWebSelection(PreviewSelection.properties(componentName, props, spec.label)),
            hidden: !showWeb,
          ),
          if (flutterContent != null)
            div(classes: 'docs-playground-pane is-flutter${showFlutter ? '' : ' is-hidden'}', [
              flutterContent,
            ]),
        ]),
      ]),
      if (hasControls)
        div(classes: 'docs-playground-controls', [
          for (final control in spec.controls) buildWebPlaygroundControl(control, props, onSetProps),
        ]),
    ]),
    codeView,
  ]);
}

Component buildWebPlaygroundControl(
  DocsPlaygroundControl control,
  Map<String, String> props,
  void Function(Map<String, String>) onSetProps,
) => switch (control) {
  DocsPlaygroundChoice(:final prop, :final options, :final segmented) => div(
    classes: 'docs-playground-control',
    [
      span(classes: 'docs-playground-label', [Text(control.label).labelSmall.onSurfaceVariant]),
      if (segmented)
        ToggleGroup<String>(
          size: CoreComponentSize.sm,
          fillWidth: true,
          value: props[prop] ?? options.first,
          onChanged: (value) => onSetProps({...props, prop: value}),
          items: [for (final option in options) CoreToggleGroupItem(value: option, label: option)],
        )
      else
        Select<String>(
          value: props[prop] ?? options.first,
          onChanged: (value) => onSetProps({...props, prop: value}),
          items: [for (final option in options) CoreSelectItem(value: option, label: option)],
        ),
    ],
  ),
  final DocsPlaygroundFlag flag => div(classes: 'docs-playground-control is-flag', [
    Text(control.label).bodyMedium.onSurface,
    Toggle(
      value: flag.isOn(props),
      onChanged: (value) => onSetProps(flag.apply(props, value: value)),
    ),
  ]),
};

Component buildWebPlaygroundRoot(Component body) {
  return div(
    classes: 'docs-playground not-content',
    attributes: {kTypographyTierAttribute: CoreBreakpointTier.desktop.name},
    [
      CoUIWeb(
        theme: ThemeData.coui,
        locale: const Locale(kDocsLanguageCode),
        child: body,
      ),
    ],
  );
}
