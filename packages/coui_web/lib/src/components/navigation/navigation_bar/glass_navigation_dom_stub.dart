/// Server-side navigation retains the selected destination's static chrome.
class GlassNavigationRuntime {
  GlassNavigationRuntime({
    required this.elementId,
    required this.onMaterialChanged,
    required this.onPreviewChanged,
    required this.onActiveChanged,
  });
  final String elementId;
  final void Function() onMaterialChanged;
  final void Function(int?) onPreviewChanged;
  final void Function(bool) onActiveChanged;
  void update({
    required bool active,
    required bool vertical,
    required int? selectedIndex,
    required List<bool> enabled,
    required void Function(int)? onSelected,
  }) {}
  void dispose() {}
}
