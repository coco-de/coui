import 'package:coui_web/coui_web.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreFilterStyle` 슬롯 전체를 여는 경로.
class FilterChainExample extends StatefulComponent {
  const FilterChainExample({super.key});

  @override
  State<FilterChainExample> createState() => _FilterChainExampleState();
}

class _FilterChainExampleState extends State<FilterChainExample> {
  String? _selected = 'svelte';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Filter<String>(
          groupValue: _selected,
          onValueChanged: handleValueChanged,
          onReset: handleReset,
          showResetButton: true,
          items: const [
            CoreFilterItem(value: 'svelte', label: 'Svelte'),
            CoreFilterItem(value: 'vue', label: 'Vue'),
            CoreFilterItem(value: 'react', label: 'React'),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Filter<String>(
          groupValue: _selected,
          onValueChanged: handleValueChanged,
          onReset: handleReset,
          showResetButton: true,
          items: const [
            CoreFilterItem(value: 'svelte', label: 'Svelte'),
            CoreFilterItem(value: 'vue', label: 'Vue'),
            CoreFilterItem(value: 'react', label: 'React'),
          ],
        ).withStyle(
          const CoreFilterStyle(
            toggleGroupStyle: CoreToggleGroupStyle(
              backgroundColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
