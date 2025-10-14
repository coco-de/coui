import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class StarRatingTile extends StatelessWidget implements IComponentPage {
  const StarRatingTile({super.key});

  @override
  String get title => 'Star Rating';

  @override
  Widget build(BuildContext context) {
    return const ComponentCard(
      name: 'star_rating',
      title: 'Star Rating',
      example: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarRating(starSize: 64, value: 3.5),
          Gap(16),
          StarRating(starSize: 64, value: 2.5),
        ],
      ),
      scale: 1,
    );
  }
}
