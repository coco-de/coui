/// Returns a Flutter code snippet string for the Listing component.
String listingCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ListingChainExample extends StatelessWidget {
  const ListingChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface.toValue();
    Widget label(String value) => Text(
      value,
      style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(color: textColor),
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
class ListingDefaultExample extends StatelessWidget {
  const ListingDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface.toValue();
    Widget label(String value) => Text(
      value,
      style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(color: textColor),
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
