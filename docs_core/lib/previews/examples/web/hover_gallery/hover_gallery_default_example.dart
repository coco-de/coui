import 'package:coui_web/coui_web.dart';

class HoverGalleryDefaultExample extends StatefulComponent {
  const HoverGalleryDefaultExample({super.key});

  @override
  State<HoverGalleryDefaultExample> createState() => _HoverGalleryDefaultExampleState();
}

class _HoverGalleryDefaultExampleState extends State<HoverGalleryDefaultExample> {
  @override
  Component build(BuildContext context) {
    return HoverGallery(
      imageUrls: [
        'https://picsum.photos/seed/a/400/300',
        'https://picsum.photos/seed/b/400/300',
        'https://picsum.photos/seed/c/400/300',
      ],
    );
  }
}
