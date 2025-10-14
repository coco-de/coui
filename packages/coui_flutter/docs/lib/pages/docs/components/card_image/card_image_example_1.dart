import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';

class CardImageExample1 extends StatelessWidget {
  const CardImageExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < 10; i++)
                CardImage(
                  image: Image.network('https://picsum.photos/200/300'),
                  onPressed: () {
                    showDialog(
                      builder: (context) {
                        return AlertDialog(
                          actions: [
                            PrimaryButton(
                              child: const Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                          content: const Text('You clicked on a card image.'),
                          title: const Text('Card Image'),
                        );
                      },
                      context: context,
                    );
                  },
                  subtitle: const Text('Lorem ipsum dolor sit amet'),
                  title: Text('Card Number ${i + 1}'),
                ),
            ],
          ).gap(8),
        ),
      ),
    );
  }
}
