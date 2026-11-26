/// Returns a Web code snippet string for the Text component.
String textCode(String? variant) {
  return switch (variant) {
    'typography-display' =>
      "Text('Display L').displayLarge\n"
          "Text('Display S').displaySmall",
    'typography-headline' =>
      "Text('Headline Large').headlineLarge\n"
          "Text('Headline Medium').headlineMedium\n"
          "Text('Headline Small').headlineSmall",
    'typography-title' =>
      "Text('Title Large').titleLarge\n"
          "Text('Title Medium').titleMedium\n"
          "Text('Title Small').titleSmall",
    'typography-body' =>
      "Text('Body Large').bodyLarge\n"
          "Text('Body Medium').bodyMedium\n"
          "Text('Body Small').bodySmall\n"
          "Text('Label Large').labelLarge\n"
          "Text('Label Medium').labelMedium\n"
          "Text('Label Small').labelSmall",
    'typography-weight' =>
      "Text('Light (300)').light\n"
          "Text('Regular (400)').regular\n"
          "Text('Medium (500)').medium\n"
          "Text('Semi Bold (600)').semiBold\n"
          "Text('Bold (700)').bold\n"
          "Text('Black (900)').black",
    'typography-primitive' =>
      "Text('s10 (10px)').s10\n"
          "Text('s14 (14px)').s14\n"
          "Text('s20 (20px)').s20\n"
          "Text('s32 (32px)').s32\n"
          "Text('h160 (line-height 1.6)').h160\n"
          "Text('tighter (-0.05em)').tighter\n"
          "Text('sans (Pretendard)').sans",
    'colors-brand' =>
      "Text('Primary').onPrimaryContainer\n"
          "Text('Secondary').onSecondaryContainer\n"
          "Text('Tertiary').onTertiaryContainer",
    'colors-status' =>
      "// A fill and its foreground are a pair — the fill is drawn as a\n"
          "// fill, with the paired foreground on top. Drawn as text on the\n"
          "// page instead, six of these eight fall under 4.5:1.\n"
          "final cs = context.theme.colorScheme;\n\n"
          "div(\n"
          "  classes: 'px-\${CoreSpace.scale.space12} "
          "py-\${CoreSpace.scale.space4} "
          "rounded-\${CoreRadius.scale.radius8} "
          "bg-\${cs.onErrorContainer} text-\${cs.onError}',\n"
          "  [Text('오류 채움').labelMedium],\n"
          ")\n\n"
          "div(\n"
          "  classes: 'px-\${CoreSpace.scale.space12} "
          "py-\${CoreSpace.scale.space4} "
          "rounded-\${CoreRadius.scale.radius8} "
          "bg-\${cs.errorContainer} text-\${cs.onErrorContainer}',\n"
          "  [Text('오류 컨테이너').labelMedium],\n"
          ")",
    'colors-surface' =>
      "// Surface tokens are background colors — visualised as filled\n"
          "// swatches with an on-surface label.\n"
          "div(\n"
          "  classes: 'inline-flex items-center self-start "
          "px-\${CoreSpace.scale.space12} "
          "py-\${CoreSpace.scale.space8} "
          "rounded-\${CoreRadius.scale.radius4} "
          "border bg-\${cs.surface.toValue()}',\n"
          "  [Text('Surface', style: TextStyle(color: 'on-surface'))],\n"
          ")\n\n"
          "Text('On surface').onSurface\n"
          "Text('Outline').outline",
    'modifiers' =>
      "Text('기울임 텍스트').italic\n"
          "Text('밑줄 텍스트').underline\n"
          "Text('취소선 텍스트').lineThrough\n"
          "Text('윗줄 텍스트').overline",
    'wrap' =>
      "Text(\n"
          "  '긴 문장...',\n"
          "  overflow: CoreTextOverflow.ellipsis,\n"
          "  maxLines: 1,\n"
          "  style: TextStyle(fontSize: CoreFontSize.s14),\n"
          ")\n\n"
          "Text('가운데 정렬', textAlign: CoreTextAlign.center)\n"
          "    .bodyMedium\n\n"
          "Text('끝 정렬', textAlign: CoreTextAlign.end)\n"
          "    .bodyMedium",
    'textstyle' =>
      "Text('bodyLarge + semiBold').bodyLarge.semiBold\n"
          "Text('bodyMedium + primary').bodyMedium.onPrimaryContainer\n"
          "Text('bodySmall + error + underline')\n"
          "    .bodySmall\n"
          "    .onErrorContainer\n"
          "    .underline\n\n"
          "Text('s14 + semiBold + primary').s14.semiBold.onPrimaryContainer",
    'opacity' =>
      "Text('opacity 1.0 (default)').bodyMedium\n"
          "Text('opacity 0.7').bodyMedium.opacity(0.7)\n"
          "Text('opacity 0.5').bodyMedium.opacity(0.5)\n"
          "Text('opacity 0.3').bodyMedium.opacity(0.3)\n"
          "Text('primary @ opacity 0.5').bodyMedium.onPrimaryContainer.opacity(0.5)\n"
          "Text('error @ opacity 0.7').bodyMedium.onErrorContainer.opacity(0.7)",
    'rich' =>
      "Text.rich(TextSpan(\n"
          "  text: '섞어 쓰기: ',\n"
          "  children: [\n"
          "    TextSpan(\n"
          "      text: '기본색 ',\n"
          "      style: TextStyle(\n"
          "        color: cs.onPrimaryContainer.toValue(),\n"
          "        fontWeight: CoreFontWeight.scale.semibold,\n"
          "      ),\n"
          "    ),\n"
          "    const TextSpan(text: '+ '),\n"
          "    TextSpan(\n"
          "      text: '기울인 오류색',\n"
          "      style: TextStyle(\n"
          "        color: cs.onErrorContainer.toValue(),\n"
          "        fontStyle: FontStyle.italic,\n"
          "      ),\n"
          "    ),\n"
          "    const TextSpan(text: ' + '),\n"
          "    const TextSpan(\n"
          "      text: '밑줄',\n"
          "      style: TextStyle(\n"
          "        decoration: CoreTextDecoration.underline,\n"
          "      ),\n"
          "    ),\n"
          "  ],\n"
          ")).bodyMedium",
    'keep-all' =>
      "// 기본 — 음절 사이에서 꺾일 수 있다\n"
          "Text('리포머 심화 플로우와 회복 스트레칭').bodyMedium\n\n"
          "// .keepAll — 어절 사이에서만 꺾는다\n"
          "Text('리포머 심화 플로우와 회복 스트레칭').bodyMedium.keepAll",
    _ => "Text('다람쥐 헌 쳇바퀴에 타고파').bodyMedium",
  };
}
