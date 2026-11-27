/// Stat 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="stat/...">` · `<Card demo>` · `<Anatomy demo>` 가 읽는다.
/// 같은 이름의 Flutter 파일(`stat_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_web.dart';
import 'stat_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _stat;

/// 장면 이름(`stat/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'stat/anatomy': () => _box(
    const Stat(
      label: page.statSampleLabel,
      value: page.statSampleValue,
      unit: page.statSampleUnit,
      change: '+20.1%',
      changeType: CoreStatChangeType.positive,
      description: page.statSampleDescription,
      icon: Icon(LucideIcons.calendar),
    ),
  ),
  'stat/trend': () => docsWebDemoRow([
    for (final sample in page.statTrendSamples) _box(_compactStat(sample), width: page.statSmallWidth),
  ]),
  'stat/unit': () => _box(
    const Stat(
      label: '활성 사용자',
      value: '128,450',
      unit: '명',
      change: '+5.2%',
      changeType: CoreStatChangeType.positive,
      description: page.statSampleDescription,
    ),
  ),
  'stat/empty': () => _box(const Stat(label: '이번 달 매출', unit: '원', description: '아직 집계되지 않았습니다')),
  'stat/do-period': () => _box(
    const Stat(
      label: '월간 매출',
      value: '1,245만',
      unit: '원',
      change: '+11.7%',
      changeType: CoreStatChangeType.positive,
      description: '지난달 대비',
    ),
  ),
  'stat/dont-period': () => _box(
    const Stat(
      label: '월간 매출',
      value: '1,245만',
      unit: '원',
      change: '+11.7%',
      changeType: CoreStatChangeType.positive,
    ),
  ),
  'stat/do-direction': () => _box(
    const Stat(
      label: '이탈률',
      value: '3.2',
      unit: '%',
      change: '+0.5%p',
      changeType: CoreStatChangeType.positive,
      statStyle: CoreStatStyle(positiveColor: CoreColor.token(CoreColors.onErrorContainer)),
    ),
  ),
  'stat/dont-direction': () => _box(
    const Stat(label: '이탈률', value: '3.2', unit: '%', change: '+0.5%p', changeType: CoreStatChangeType.negative),
  ),
  'stat/do-unit': () => _box(const Stat(label: '방문자', value: '15,234', unit: '명')),
  'stat/dont-unit': () => _box(const Stat(label: '방문자', value: '15234')),
  'stat/grid': _grid,
  'stat/long-text': () => _box(
    const Stat(label: '누적 거래액', value: '1,234,567,890,000', unit: '원', description: '설명 줄이 길면 카드 폭에 맞춰 줄이 바뀝니다'),
  ),
  'stat/display': () => _box(
    const Stat(
      label: '활성 사용자',
      value: '128,450',
      unit: '명',
      statStyle: CoreStatStyle(valueTextStyle: CoreTextStyle.token(CoreTextStyles.displaySmall)),
    ),
    width: page.statWideWidth,
  ),
  'stat/plain': () => _box(
    const Stat(
      label: '활성 사용자',
      value: '128,450',
      unit: '명',
      variant: CoreStatVariant.filled,
      statStyle: CoreStatStyle(backgroundColor: CoreColor.transparent, borderRadius: CoreBorderRadius.zero),
    ),
  ),
  'stat/related-card': () => _box(Card(child: const Text('자유로운 내용').bodyMedium), width: page.statSmallWidth),
  'stat/related-progress': () => _box(const Progress(value: 0.6), width: page.statSmallWidth),
  // `initialValue` 를 주지 않아 처음부터 목표 숫자를 그린다.
  'stat/related-number-ticker': () => const NumberTicker(value: page.statTickerValue, formatter: page.statTickerText),
};

/// 폭을 정한 상자 — Stat 은 부모의 폭을 채운다.
Component _box(Component child, {double width = page.statSceneWidth}) =>
    div(styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}), [child]);

Component _stat(Map<String, String> props, String? label) {
  final change = page.statPreviewChange(props);
  return _box(
    Stat(
      label: label ?? page.statSampleLabel,
      value: previewFlag(props, 'empty') ? null : page.statSampleValue,
      unit: previewFlag(props, 'unit') ? page.statSampleUnit : null,
      variant: previewEnum(CoreStatVariant.values, props['variant'], CoreStatVariant.defaultVariant),
      size: page.statPreviewSize(props),
      change: change == null ? null : page.statSampleChanges[change],
      changeType: change,
      description: previewFlag(props, 'description') ? page.statSampleDescription : null,
      icon: docsWebIcon(props['icon']),
    ),
  );
}

Component _compactStat(page.StatSample sample) => Stat(
  label: sample.label,
  value: sample.value,
  unit: sample.unit,
  size: CoreComponentSize.sm,
  change: sample.change,
  changeType: sample.type,
);

/// 두 열 격자.
Component _grid() => div(
  styles: Styles(
    raw: {
      'display': 'grid',
      'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      'gap': spaceCss(CoreSpace.space12),
      'width': pinnedLengthCss(page.statGridWidth),
      'max-width': '100%',
    },
  ),
  [for (final sample in page.statGridSamples) _compactStat(sample)],
);
