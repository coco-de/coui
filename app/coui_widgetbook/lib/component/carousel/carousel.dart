import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A sliding [coui.Carousel] use case.
@UseCase(
  name: 'sliding',
  type: coui.Carousel,
)
Widget buildCarouselSlidingUseCase(BuildContext context) {
  final controller = coui.CarouselController();
  final itemCount = context.knobs.int.slider(
    initialValue: 5,
    label: 'itemCount',
    max: 10,
    min: 3,
  );

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        height: 200,
        child: coui.Carousel(
          alignment: context.knobs.list(
            initialOption: coui.CarouselAlignment.center,
            label: 'alignment',
            options: coui.CarouselAlignment.values,
          ),
          autoplaySpeed: context.knobs.boolean(
                    initialValue: false,
                    label: 'autoplay',
                  )
              ? Duration(
                  milliseconds: context.knobs.int.slider(
                    initialValue: 3000,
                    label: 'autoplay speed (ms)',
                    max: 5000,
                    min: 1000,
                  ),
                )
              : null,
          controller: controller,
          draggable: context.knobs.boolean(initialValue: true, label: 'draggable'),
          itemBuilder: (context, index) {
            final colors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
              Colors.teal,
              Colors.pink,
              Colors.indigo,
              Colors.amber,
              Colors.cyan,
            ];
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors[index % colors.length],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Slide ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          itemCount: itemCount,
          pauseOnHover: context.knobs.boolean(
            initialValue: true,
            label: 'pause on hover',
          ),
          sizeConstraint: coui.CarouselSizeConstraint.fractional(
            context.knobs.double.slider(
              initialValue: 0.8,
              label: 'size fraction',
              max: 1.0,
              min: 0.3,
            ),
          ),
          transition: coui.CarouselTransition.sliding(
            gap: context.knobs.double.slider(
              initialValue: 16,
              label: 'gap',
              max: 32,
              min: 0,
            ),
          ),
          wrap: context.knobs.boolean(initialValue: true, label: 'wrap'),
        ),
      ),
      const SizedBox(height: 16),
      coui.CarouselDotIndicator(
        controller: controller,
        itemCount: itemCount,
      ),
    ],
  );
}

/// A fading [coui.Carousel] use case.
@UseCase(
  name: 'fading',
  type: coui.Carousel,
)
Widget buildCarouselFadingUseCase(BuildContext context) {
  final controller = coui.CarouselController();
  final itemCount = context.knobs.int.slider(
    initialValue: 5,
    label: 'itemCount',
    max: 10,
    min: 3,
  );

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        height: 200,
        child: coui.Carousel(
          autoplaySpeed: context.knobs.boolean(
                    initialValue: true,
                    label: 'autoplay',
                  )
              ? Duration(
                  milliseconds: context.knobs.int.slider(
                    initialValue: 3000,
                    label: 'autoplay speed (ms)',
                    max: 5000,
                    min: 1000,
                  ),
                )
              : null,
          controller: controller,
          itemBuilder: (context, index) {
            final colors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ];
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors[index % colors.length],
              ),
              child: Text(
                'Slide ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          itemCount: itemCount,
          transition: const coui.CarouselTransition.fading(),
        ),
      ),
      const SizedBox(height: 16),
      coui.CarouselDotIndicator(
        controller: controller,
        itemCount: itemCount,
      ),
    ],
  );
}

/// A vertical [coui.Carousel] use case.
@UseCase(
  name: 'vertical',
  type: coui.Carousel,
)
Widget buildCarouselVerticalUseCase(BuildContext context) {
  return SizedBox(
    height: 400,
    width: 200,
    child: coui.Carousel(
      direction: Axis.vertical,
      itemBuilder: (context, index) {
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
        ];
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colors[index % colors.length],
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Slide ${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
      itemCount: 5,
      sizeConstraint: const coui.CarouselSizeConstraint.fractional(0.8),
      transition: const coui.CarouselTransition.sliding(gap: 16),
    ),
  );
}