import 'package:coui_web/coui_web.dart';
import 'package:docs_core/shared/chain_tier1.dart';

import 'chain_shuffle_control.dart';
import 'chain_code_dom.dart';
import 'live_preview_panel.dart';
import 'package:docs_core/shared/docs_locale.dart';

/// One live example at a time, including its paired Web and Flutter views.
@client
class PreviewGallery extends StatefulComponent {
  const PreviewGallery({required this.componentName, required this.variants, required this.panelId, super.key});

  final String componentName;
  final List<String> variants;
  final String panelId;

  @override
  State<PreviewGallery> createState() => _PreviewGalleryState();
}

class _PreviewGalleryState extends State<PreviewGallery> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    // Keep the first client frame identical to SSR, then reveal a shared
    // chain permutation if the URL points to this gallery's control.
    context.binding.addPostFrameCallback(() {
      final step = int.tryParse(readQueryParam(component.panelId) ?? '');
      final chainIndex = component.variants.indexOf('chain');
      if (mounted && step != null && step > 0 && chainIndex >= 0) {
        setState(() => _selected = chainIndex);
      }
    });
  }

  @override
  Component build(BuildContext context) {
    final variant = component.variants[_selected];
    final isChain = variant == 'chain';
    return CoUIWeb(
      theme: ThemeData.coui,
      locale: const Locale(kDocsLanguageCode),
      child: div(classes: 'variant-gallery-wrap not-content', [
        div(classes: 'preview-variant-controls', [
          div(classes: 'preview-variant-tabs', [
            Tabs(
              attributes: const {'aria-label': '예제 변형'},
              tabs: [for (final value in component.variants) CoreTabItem(label: value == 'chain' ? '스타일 조합' : value)],
              selectedIndex: _selected,
              onChanged: (index) => setState(() => _selected = index),
            ),
          ]),
          if (isChain && kChainTier1Components.contains(component.componentName))
            ChainShuffleContent(panelId: component.panelId, component: component.componentName),
        ]),
        div(classes: 'variant-gallery', [
          LivePreviewPanel(
            key: ValueKey(variant),
            componentName: component.componentName,
            parentOwnsHydration: true,
            variant: variant,
            panelId: isChain ? component.panelId : null,
          ),
        ]),
      ]),
    );
  }
}
