import 'package:coui_flutter/coui_flutter.dart';

class ColorPickerExample2 extends StatelessWidget {
  const ColorPickerExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Pick Color'),
      onPressed: () async {
        final history = ColorHistoryStorage.of(context);
        final result = await pickColorFromScreen(context, history);
        if (result != null && context.mounted) {
          showToast(
            builder: (context, overlay) {
              return SurfaceCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Color: ${colorToHex(result)}'),
                    const Gap(16),
                    Container(
                      decoration: BoxDecoration(
                        color: result,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: 24,
                      height: 24,
                    ),
                  ],
                ),
              );
            },
            context: context,
          );
        }
      },
    );
  }
}
