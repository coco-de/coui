import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Card] use case.
@UseCase(
  name: 'default',
  type: coui.Card,
)
Widget buildCardDefaultUseCase(BuildContext context) {
  return coui.Card(
    borderColor: context.knobs.colorOrNull(label: 'borderColor'),
    borderRadius: BorderRadius.circular(
      context.knobs.double.slider(
        initialValue: 8,
        label: 'borderRadius',
        max: 32,
      ),
    ),
    borderWidth: context.knobs.doubleOrNull.slider(
      label: 'borderWidth',
      max: 4,
    ),
    fillColor: context.knobs.colorOrNull(label: 'fillColor'),
    filled: context.knobs.booleanOrNull(label: 'filled'),
    padding: EdgeInsets.all(
      context.knobs.double.slider(
        initialValue: 16,
        label: 'padding',
        max: 32,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Title',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'This is a card with some content.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// A filled [coui.Card] use case.
@UseCase(
  name: 'filled',
  type: coui.Card,
)
Widget buildCardFilledUseCase(BuildContext context) {
  return coui.Card(
    borderRadius: BorderRadius.circular(12),
    fillColor: Colors.blue.shade50,
    filled: true,
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info, color: Colors.blue, size: 32),
        const SizedBox(height: 12),
        Text(
          'Filled Card',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.blue.shade900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'This card has a filled background color.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// An outlined [coui.Card] use case.
@UseCase(
  name: 'outlined',
  type: coui.Card,
)
Widget buildCardOutlinedUseCase(BuildContext context) {
  return coui.Card(
    borderColor: Colors.grey.shade300,
    borderRadius: BorderRadius.circular(12),
    borderWidth: 2,
    filled: false,
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outlined Card',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'This card has a border without a fill.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// An elevated [coui.Card] use case with shadow.
@UseCase(
  name: 'elevated',
  type: coui.Card,
)
Widget buildCardElevatedUseCase(BuildContext context) {
  return coui.Card(
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        blurRadius: context.knobs.double.slider(
          initialValue: 8,
          label: 'blur radius',
          max: 32,
        ),
        color: Colors.black.withOpacity(
          context.knobs.double.slider(
            initialValue: 0.1,
            label: 'shadow opacity',
            max: 0.5,
          ),
        ),
        offset: Offset(
          0,
          context.knobs.double.slider(
            initialValue: 4,
            label: 'shadow offset',
            max: 16,
          ),
        ),
      ),
    ],
    fillColor: Colors.white,
    filled: true,
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elevated Card',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'This card has a shadow for elevation effect.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// A surface [coui.SurfaceCard] use case with blur.
@UseCase(
  name: 'surface',
  type: coui.SurfaceCard,
)
Widget buildCardSurfaceUseCase(BuildContext context) {
  return Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            colors: [Colors.purple, Colors.blue],
            end: Alignment.bottomRight,
          ),
        ),
        height: 300,
      ),
      Center(
        child: coui.SurfaceCard(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(24),
          surfaceBlur: context.knobs.double.slider(
            initialValue: 10,
            label: 'blur',
            max: 30,
          ),
          surfaceOpacity: context.knobs.double.slider(
            initialValue: 0.7,
            label: 'opacity',
            max: 1,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Surface Card',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'This card has a blur effect.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}