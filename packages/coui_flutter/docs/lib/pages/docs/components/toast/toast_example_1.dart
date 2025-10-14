import 'package:coui_flutter/coui_flutter.dart';

class ToastExample1 extends StatefulWidget {
  const ToastExample1({super.key});

  @override
  State<ToastExample1> createState() => _ToastExample1State();
}

class _ToastExample1State extends State<ToastExample1> {
  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        subtitle: const Text('Sunday, July 07, 2024 at 12:00 PM'),
        title: const Text('Event has been created'),
        trailing: PrimaryButton(
          onPressed: () {
            overlay.close();
          },
          size: ButtonSize.small,
          child: const Text('Undo'),
        ),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PrimaryButton(
          child: const Text('Show Bottom Left Toast'),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.bottomLeft,
            );
          },
        ),
        PrimaryButton(
          child: const Text('Show Bottom Right Toast'),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.bottomRight,
            );
          },
        ),
        PrimaryButton(
          child: const Text('Show Top Left Toast'),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.topLeft,
            );
          },
        ),
        PrimaryButton(
          child: const Text('Show Top Right Toast'),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.topRight,
            );
          },
        ),
        // bottom center
        PrimaryButton(
          child: const Text('Show Bottom Center Toast'),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.bottomCenter,
            );
          },
        ),
        // top center
        PrimaryButton(
          child: const Text('Show Top Center Toast'),
          onPressed: () {
            showToast(
              builder: buildToast,
              context: context,
              location: ToastLocation.topCenter,
            );
          },
        ),
      ],
    );
  }
}
