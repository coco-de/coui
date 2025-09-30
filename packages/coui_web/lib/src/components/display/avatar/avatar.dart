import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/avatar/avatar_style.dart';
import 'package:jaspr/jaspr.dart';

/// Avatar size variants matching coui_flutter API.
enum AvatarSize {
  /// Large avatar size.
  lg,

  /// Medium avatar size.
  md,

  /// Small avatar size.
  sm,

  /// Extra large avatar size.
  xl,

  /// Extra small avatar size.
  xs,
}

/// Avatar shape variants.
enum AvatarShape {
  /// Circle avatar shape.
  circle,

  /// Rounded avatar shape.
  rounded,

  /// Square avatar shape.
  square,
}

/// A component for displaying user avatars with images, initials, or placeholders.
///
/// Avatars can display profile images, fallback to initials, show online status,
/// and support various sizes and shapes. Compatible with coui_flutter API.
///
/// Example:
/// ```dart
/// Avatar(
///   imageUrl: 'https://example.com/avatar.jpg',
///   initials: 'JD',
///   size: AvatarSize.md,
/// )
/// ```
class Avatar extends UiComponent {
  /// Creates an Avatar component.
  ///
  /// - [imageUrl]: URL of the image to display.
  /// - [initials]: Text to display when no image is available.
  /// - [placeholder]: Custom placeholder widget when no image or initials.
  /// - [size]: Size of the avatar (xs, sm, md, lg, xl).
  /// - [shape]: Shape of the avatar (circle, rounded, square).
  /// - [online]: Whether to show online status indicator.
  /// - [offline]: Whether to show offline status indicator.
  /// - [style]: List of [AvatarStyling] instances for styling.
  Avatar({
    super.attributes,
    super.classes,
    super.css,
    super.id,
    this.imageUrl,
    this.initials,
    super.key,
    this.offline = false,
    this.online = false,
    this.placeholder,
    this.shape,
    this.size,
    List<AvatarStyling>? style,
    super.tag = _defaultTag,
  }) : _style = style,
       super(
         null,
         child: null,
         style: style,
       );

  /// URL of the avatar image.
  final String? imageUrl;

  /// Initials to display when no image is available.
  final String? initials;

  /// Custom placeholder content.
  final Component? placeholder;

  /// Size of the avatar.
  final AvatarSize? size;

  /// Shape of the avatar.
  final AvatarShape? shape;

  /// Whether to show online status indicator.
  final bool online;

  /// Whether to show offline status indicator.
  final bool offline;

  /// Internal style list.
  final List<AvatarStyling>? _style;

  // --- Static Avatar Style Modifiers ---

  /// Online status indicator. `avatar-online`.
  static const onlineStyle = AvatarStyle(
    'avatar-online',
    type: StyleType.state,
  );

  /// Offline status indicator. `avatar-offline`.
  static const offlineStyle = AvatarStyle(
    'avatar-offline',
    type: StyleType.state,
  );

  /// Placeholder style. `avatar-placeholder`.
  static const placeholderStyle = AvatarStyle(
    'avatar-placeholder',
    type: StyleType.style,
  );

  /// Rounded shape style. `rounded-full`.
  static const roundedStyle = AvatarStyle(
    'rounded-full',
    type: StyleType.form,
  );

  /// Square shape style. `rounded-none`.
  static const squareStyle = AvatarStyle('rounded-none', type: StyleType.form);

  static const _defaultTag = 'div';
  static const _avatarBaseClass = 'avatar';
  static const _imgTag = 'img';
  static const _divTag = 'div';
  static const _spanTag = 'span';
  static const _srcAttribute = 'src';
  static const _altAttribute = 'alt';
  static const _avatarInitials = 'Avatar';
  static const _sizeXs = 'w-8 h-8';
  static const _sizeSm = 'w-12 h-12';
  static const _sizeMd = 'w-16 h-16';
  static const _sizeLg = 'w-20 h-20';
  static const _sizeXl = 'w-24 h-24';

  @override
  String get baseClass => _avatarBaseClass;

  @override
  Component build(BuildContext context) {
    final styles = _buildStyles();
    final sizeClass = _getSizeClass();
    final shapeClass = _getShapeClass();

    // Build inner content
    final content = _buildContent();

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}${sizeClass.isNotEmpty ? ' $sizeClass' : ''}${shapeClass.isNotEmpty ? ' $shapeClass' : ''}',
      id: id,
      styles: css,
      tag: tag,
      children: [content],
    );
  }

  List<String> _buildStyles() {
    final stylesList = <String>[];

    if (_style != null) {
      for (final style in _style!) {
        stylesList.add(style.cssClass);
      }
    }

    if (online) {
      stylesList.add(onlineStyle.cssClass);
    }

    if (offline) {
      stylesList.add(offlineStyle.cssClass);
    }

    if (imageUrl == null && initials == null && placeholder == null) {
      stylesList.add(placeholderStyle.cssClass);
    }

    return stylesList;
  }

  String _getSizeClass() {
    if (size == null) return '';

    switch (size!) {
      case AvatarSize.xs:
        return _sizeXs;

      case AvatarSize.sm:
        return _sizeSm;

      case AvatarSize.md:
        return _sizeMd;

      case AvatarSize.lg:
        return _sizeLg;

      case AvatarSize.xl:
        return _sizeXl;
    }
  }

  String _getShapeClass() {
    if (shape == null) return '';

    switch (shape!) {
      case AvatarShape.circle:
        return roundedStyle.cssClass;

      case AvatarShape.rounded:
        return 'rounded-lg';

      case AvatarShape.square:
        return squareStyle.cssClass;
    }
  }

  Component _buildContent() {
    // If image URL is provided, show image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Component.element(
        attributes: {
          _srcAttribute: imageUrl!,
          _altAttribute: initials ?? _avatarInitials,
        },
        tag: _imgTag,
      );
    }

    // If initials are provided, show initials
    if (initials != null && initials!.isNotEmpty) {
      return Component.element(
        tag: _divTag,
        children: [
          Component.element(
            tag: _spanTag,
            children: [Component.text(initials!)],
          ),
        ],
      );
    }

    // If placeholder is provided, show placeholder
    if (placeholder != null) {
      return placeholder!;
    }

    // Default empty placeholder
    return Component.element(
      tag: _divTag,
      children: const [],
    );
  }

  @override
  Avatar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? imageUrl,
    String? initials,
    Key? key,
    bool? offline,
    bool? online,
    Component? placeholder,
    AvatarShape? shape,
    AvatarSize? size,
    List<AvatarStyling>? style,
    String? tag,
  }) {
    return Avatar(
      attributes: attributes ?? userProvidedAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      initials: initials ?? this.initials,
      key: key ?? this.key,
      offline: offline ?? this.offline,
      online: online ?? this.online,
      placeholder: placeholder ?? this.placeholder,
      shape: shape ?? this.shape,
      size: size ?? this.size,
      style: style ?? _style,
      tag: tag ?? this.tag,
    );
  }
}

/// Configuration for creating avatar groups.
class AvatarGroupConfig {
  /// Creates an [AvatarGroupConfig].
  const AvatarGroupConfig({
    this.max,
    this.spacing,
  });

  /// Maximum number of avatars to display before showing "+N" indicator.
  final int? max;

  /// Spacing between avatars (negative for overlap).
  final double? spacing;
}

/// Helper methods for creating avatar groups and patterns.
abstract final class AvatarHelper {
  /// Creates a group of avatars with optional overlap.
  static Component createAvatarGroup({
    required List<Avatar> avatars,
    AvatarGroupConfig? config,
    Key? key,
  }) {
    final maxAvatars = config?.max;
    final displayAvatars = maxAvatars != null && avatars.length > maxAvatars
        ? avatars.sublist(0, maxAvatars)
        : avatars;

    final remainingCount = maxAvatars != null && avatars.length > maxAvatars
        ? avatars.length - maxAvatars
        : 0;

    return Component.element(
      classes: 'avatar-group',
      key: key,
      tag: 'div',
      children: [
        ...displayAvatars,
        if (remainingCount > 0)
          Avatar(
            initials: '+$remainingCount',
            style: const [Avatar.placeholderStyle],
          ),
      ],
    );
  }
}
