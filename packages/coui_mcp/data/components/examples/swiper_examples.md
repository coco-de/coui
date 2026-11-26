# Swiper Examples

This document contains example code for the swiper component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';

class SwiperExample1 extends StatefulWidget {
  const SwiperExample1({super.key});

  @override
  State<SwiperExample1> createState() => _SwiperExample1State();
}

class _SwiperExample1State extends State<SwiperExample1> {
  OverlayPosition _position = OverlayPosition.end;
  bool _typeDrawer = true;

  Widget _buildSelectPosition(OverlayPosition position, String label) {
    return SelectedButton(
      value: _position == position,
      onChanged: (value) {
        if (value) {
          setState(() {
            _position = position;
          });
        }
      },
      style: const ButtonStyle.outline(),
      selectedStyle: const ButtonStyle.primary(),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Swiper(
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(minWidth: 320, minHeight: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hello!'),
              const Gap(size: 24),
              PrimaryButton(
                child: const Text('Close'),
                onPressed: () {
                  openDrawer(
                    builder: (context) {
                      return ListView.separated(
                        itemBuilder: (context, index) {
                          return Card(child: Text('Item $index'));
                        },
                        separatorBuilder: (context, index) {
                          return const Gap(size: 8);
                        },
                        itemCount: 1000,
                      );
                    },
                    context: context,
                    position: OverlayPosition.bottom,
                  );
                },
              ),
            ],
          ),
        );
      },
      handler: _typeDrawer ? SwiperHandler.drawer : SwiperHandler.sheet,
      position: _position,
      child: SizedBox(
        height: 500,
        child: Card(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Swipe me!'),
                const Gap(size: 24),
                ButtonGroup(
                  children: [
                    _buildSelectPosition(OverlayPosition.left, 'Left'),
                    _buildSelectPosition(OverlayPosition.right, 'Right'),
                    _buildSelectPosition(OverlayPosition.top, 'Top'),
                    _buildSelectPosition(OverlayPosition.bottom, 'Bottom'),
                  ],
                ),
                const Gap(size: 24),
                ButtonGroup(
                  children: [
                    Toggle(
                      onChanged: (value) {
                        setState(() {
                          _typeDrawer = value;
                        });
                      },
                      trailing: const Text('Drawer'),
                      value: _typeDrawer,
                    ),
                    Toggle(
                      onChanged: (value) {
                        setState(() {
                          _typeDrawer = !value;
                        });
                      },
                      trailing: const Text('Sheet'),
                      value: !_typeDrawer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

```

