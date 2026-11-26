/// Returns a Web code snippet string for the Listing component.
String listingCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ListingChainExample extends StatelessComponent {
  const ListingChainExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    Component label(String value) => div(
      [Text(value)],
      classes: 'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}',
    );

    return Listing(
      itemBorder: true,
      children: [
        ListRow(
          children: [
            ListCol(child: label('김코드')),
            ListCol(child: label('alice@example.com')),
            ListCol(child: label('관리자')),
          ],
        ),
        ListRow(
          children: [
            ListCol(child: label('이코드')),
            ListCol(child: label('bob@example.com')),
            ListCol(child: label('멤버')),
          ],
        ),
        ListRow(
          children: [
            ListCol(child: label('박코드')),
            ListCol(child: label('cam@example.com')),
            ListCol(child: label('뷰어')),
          ],
        ),
      ],
    ).withStyle(
      const CoreListingStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space16),
        colSpacing: CoreSpace.space24,
        dividerStyle: CoreDividerStyle(
          color: CoreColor.token(CoreColors.primary),
          thickness: CoreStrokeWidth.stroke2,
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class ListingDefaultExample extends StatelessComponent {
  const ListingDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    Component label(String value) => div(
      [Text(value)],
      classes: 'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}',
    );

    return Listing(
      itemBorder: true,
      children: [
        ListRow(
          children: [
            ListCol(child: label('김코드')),
            ListCol(child: label('alice@example.com')),
            ListCol(child: label('관리자')),
          ],
        ),
        ListRow(
          children: [
            ListCol(child: label('이코드')),
            ListCol(child: label('bob@example.com')),
            ListCol(child: label('멤버')),
          ],
        ),
        ListRow(
          children: [
            ListCol(child: label('박코드')),
            ListCol(child: label('cam@example.com')),
            ListCol(child: label('뷰어')),
          ],
        ),
      ],
    );
  }
}''',
  };
}
