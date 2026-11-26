import 'package:coui_flutter/coui_flutter.dart';

/// Default preview for `CardImage`. Uses a fixed 240 × 160 image + a
/// fixed 240 px card width so Flutter/Web render at identical size
/// regardless of the preview panel.
class CardImageDefaultExample extends StatelessWidget {
  const CardImageDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: CardImage(
        image: Image.network(
          'https://picsum.photos/seed/coui/240/160',
          width: 240,
          height: 160,
          fit: BoxFit.cover,
        ),
        title: const Text('산 풍경'),
        subtitle: const Text('해 뜰 무렵 촬영'),
        onPressed: () {},
      ),
    );
  }
}
