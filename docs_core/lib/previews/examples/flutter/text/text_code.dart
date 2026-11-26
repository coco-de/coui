/// Returns a Flutter code snippet string for the Text component.
String textCode(String? variant) {
  return switch (variant) {
    'typography-display' =>
      "const Text('Display L').displayLarge\n"
          "const Text('Display S').displaySmall",
    'typography-headline' =>
      "const Text('Headline Large').headlineLarge\n"
          "const Text('Headline Medium').headlineMedium\n"
          "const Text('Headline Small').headlineSmall",
    'typography-title' =>
      "const Text('Title Large').titleLarge\n"
          "const Text('Title Medium').titleMedium\n"
          "const Text('Title Small').titleSmall",
    'typography-body' =>
      "const Text('Body Large').bodyLarge\n"
          "const Text('Body Medium').bodyMedium\n"
          "const Text('Body Small').bodySmall\n"
          "const Text('Label Large').labelLarge\n"
          "const Text('Label Medium').labelMedium\n"
          "const Text('Label Small').labelSmall",
    'typography-weight' =>
      "const Text('Light (300)').light\n"
          "const Text('Regular (400)').regular\n"
          "const Text('Medium (500)').medium\n"
          "const Text('Semi Bold (600)').semiBold\n"
          "const Text('Bold (700)').bold\n"
          "const Text('Black (900)').black",
    'typography-primitive' =>
      "const Text('s10 (10px)').s10\n"
          "const Text('s14 (14px)').s14\n"
          "const Text('s20 (20px)').s20\n"
          "const Text('s32 (32px)').s32\n"
          "const Text('h160 (line-height 1.6)').h160\n"
          "const Text('tighter (-0.05em)').tighter\n"
          "const Text('sans (Pretendard)').sans",
    'colors-brand' =>
      "const Text('Primary').onPrimaryContainer\n"
          "const Text('Secondary').onSecondaryContainer\n"
          "const Text('Tertiary').onTertiaryContainer",
    'colors-status' =>
      "// A fill and its foreground are a pair — the fill is drawn as a\n"
          "// fill, with the paired foreground on top. Drawn as text on the\n"
          "// page instead, six of these eight fall under 4.5:1.\n"
          "final cs = Theme.of(context).colorScheme;\n\n"
          "DecoratedBox(\n"
          "  decoration: BoxDecoration(\n"
          "    color: cs.onErrorContainer!.toValue(),\n"
          "    borderRadius: BorderRadius.circular(CoreRadius.radius8),\n"
          "  ),\n"
          "  child: Padding(\n"
          "    padding: const CoreEdgeInsets.symmetric(\n"
          "      horizontal: CoreSpace.space12,\n"
          "      vertical: CoreSpace.space4,\n"
          "    ).toValue(geometry: Theme.of(context).geometry),\n"
          "    child: Text('오류 채움', style: labelMedium.copyWith(\n"
          "      color: cs.onError!.toValue(),\n"
          "    )),\n"
          "  ),\n"
          ")",
    'colors-surface' =>
      "// Surface tokens are background colors — visualised as filled\n"
          "// swatches. Inner Text uses chain `.bodyMedium` so the swatch\n"
          "// label always renders with the project base typography.\n"
          "Container(\n"
          "  padding: const CoreEdgeInsets.symmetric(\n"
          "    horizontal: CoreSpace.space12,\n"
          "    vertical: CoreSpace.space8,\n"
          "  ).toValue(geometry: Theme.of(context).geometry),\n"
          "  decoration: BoxDecoration(\n"
          "    color: cs.surface.toValue(),\n"
          "    borderRadius: BorderRadius.circular(CoreRadius.radius4),\n"
          "    border: Border.all(color: cs.outlineVariant.toValue()),\n"
          "  ),\n"
          "  child: const Text('Surface').bodyMedium,\n"
          ")\n\n"
          "const Text('On surface').onSurface\n"
          "const Text('Outline').outline",
    'modifiers' =>
      "const Text('기울임 텍스트').italic\n"
          "const Text('밑줄 텍스트').underline\n"
          "const Text('취소선 텍스트').lineThrough\n"
          "const Text('윗줄 텍스트').overline",
    'wrap' =>
      "const Text(\n"
          "  '긴 문장...',\n"
          "  overflow: TextOverflow.ellipsis,\n"
          "  maxLines: 1,\n"
          "  style: TextStyle(fontSize: CoreFontSize.s14),\n"
          ")\n\n"
          "const Text(\n"
          "  '가운데 정렬',\n"
          "  textAlign: TextAlign.center,\n"
          ").bodyMedium\n\n"
          "const Text(\n"
          "  '끝 정렬',\n"
          "  textAlign: TextAlign.end,\n"
          ").bodyMedium",
    'textstyle' =>
      "const Text('bodyLarge + semiBold').bodyLarge.semiBold\n"
          "const Text('bodyMedium + primary').bodyMedium.onPrimaryContainer\n"
          "const Text('bodySmall + error + underline')\n"
          "    .bodySmall\n"
          "    .onErrorContainer\n"
          "    .underline\n\n"
          "const Text('s14 + semiBold + primary').s14.semiBold.onPrimaryContainer",
    'opacity' =>
      "const Text('opacity 1.0 (default)').bodyMedium\n"
          "const Text('opacity 0.7').bodyMedium.opacity(0.7)\n"
          "const Text('opacity 0.5').bodyMedium.opacity(0.5)\n"
          "const Text('opacity 0.3').bodyMedium.opacity(0.3)\n"
          "const Text('primary @ opacity 0.5').bodyMedium.onPrimaryContainer.opacity(0.5)\n"
          "const Text('error @ opacity 0.7').bodyMedium.onErrorContainer.opacity(0.7)",
    'rich' =>
      "Text.rich(\n"
          "  TextSpan(\n"
          "    text: '섞어 쓰기: ',\n"
          "    children: [\n"
          "      TextSpan(\n"
          "        text: '기본색 ',\n"
          "        style: TextStyle(\n"
          "          color: cs.onPrimaryContainer.toValue(),\n"
          "          fontWeight: FontWeight.w600,\n"
          "        ),\n"
          "      ),\n"
          "      const TextSpan(text: '+ '),\n"
          "      TextSpan(\n"
          "        text: '기울인 오류색',\n"
          "        style: TextStyle(\n"
          "          color: cs.onErrorContainer.toValue(),\n"
          "          fontStyle: FontStyle.italic,\n"
          "        ),\n"
          "      ),\n"
          "      const TextSpan(text: ' + '),\n"
          "      const TextSpan(\n"
          "        text: '밑줄',\n"
          "        style: TextStyle(\n"
          "          decoration: TextDecoration.underline,\n"
          "        ),\n"
          "      ),\n"
          "    ],\n"
          "  ),\n"
          "  style: ts.bodyMedium.toValue(theme: Theme.of(context)),\n"
          ")",
    'keep-all' =>
      "// 기본 — 음절 사이에서 꺾일 수 있다\n"
          "const Text('리포머 심화 플로우와 회복 스트레칭').bodyMedium\n\n"
          "// .keepAll — 어절 사이에서만 꺾는다\n"
          "const Text('리포머 심화 플로우와 회복 스트레칭').bodyMedium.keepAll",
    _ => "const Text('다람쥐 헌 쳇바퀴에 타고파').bodyMedium",
  };
}
