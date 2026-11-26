// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:docs_core/components/web_preview.dart' as _web_preview;
import 'package:docs_site/components/chain_shuffle_control.dart'
    as _chain_shuffle_control;
import 'package:docs_site/components/docs_playground.dart' as _docs_playground;
import 'package:docs_site/components/docs_search.dart' as _docs_search;
import 'package:docs_site/components/flutter_preview.dart' as _flutter_preview;
import 'package:docs_site/components/preview_gallery.dart' as _preview_gallery;
import 'package:docs_site/components/site_theme_controls.dart'
    as _site_theme_controls;
import 'package:docs_site/components/site_theme_toggle.dart'
    as _site_theme_toggle;
import 'package:docs_site/components/typed_callout.dart' as _typed_callout;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    as _zoomable_image;
import 'package:jaspr_content/components/callout.dart' as _callout;
import 'package:jaspr_content/components/image.dart' as _image;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _web_preview.WebPreview: ClientTarget<_web_preview.WebPreview>(
      'docs_core:web_preview',
      params: __web_previewWebPreview,
    ),
    _chain_shuffle_control.ChainShuffleControl:
        ClientTarget<_chain_shuffle_control.ChainShuffleControl>(
          'chain_shuffle_control',
          params: __chain_shuffle_controlChainShuffleControl,
        ),
    _docs_playground.DocsPlayground:
        ClientTarget<_docs_playground.DocsPlayground>(
          'docs_playground',
          params: __docs_playgroundDocsPlayground,
        ),
    _docs_search.DocsSearch: ClientTarget<_docs_search.DocsSearch>(
      'docs_search',
    ),
    _flutter_preview.FlutterPreview:
        ClientTarget<_flutter_preview.FlutterPreview>(
          'flutter_preview',
          params: __flutter_previewFlutterPreview,
        ),
    _preview_gallery.PreviewGallery:
        ClientTarget<_preview_gallery.PreviewGallery>(
          'preview_gallery',
          params: __preview_galleryPreviewGallery,
        ),
    _site_theme_controls.SiteThemeControls:
        ClientTarget<_site_theme_controls.SiteThemeControls>(
          'site_theme_controls',
        ),
    _site_theme_toggle.SiteThemeToggle:
        ClientTarget<_site_theme_toggle.SiteThemeToggle>('site_theme_toggle'),
    _zoomable_image.ZoomableImage: ClientTarget<_zoomable_image.ZoomableImage>(
      'jaspr_content:zoomable_image',
      params: __zoomable_imageZoomableImage,
    ),
  },
  styles: () => [
    ..._typed_callout.TypedCallout.styles,
    ..._callout.Callout.styles,
    ..._image.Image.styles,
    ..._zoomable_image.ZoomableImage.styles,
  ],
);

Map<String, Object?> __web_previewWebPreview(_web_preview.WebPreview c) => {
  'component': c.component,
  'variant': c.variant,
  'panelId': c.panelId,
  'chainStep': c.chainStep,
};
Map<String, Object?> __chain_shuffle_controlChainShuffleControl(
  _chain_shuffle_control.ChainShuffleControl c,
) => {'panelId': c.panelId, 'component': c.component};
Map<String, Object?> __docs_playgroundDocsPlayground(
  _docs_playground.DocsPlayground c,
) => {'component': c.component, 'panelId': c.panelId};
Map<String, Object?> __flutter_previewFlutterPreview(
  _flutter_preview.FlutterPreview c,
) => {'component': c.component, 'variant': c.variant, 'panelId': c.panelId};
Map<String, Object?> __preview_galleryPreviewGallery(
  _preview_gallery.PreviewGallery c,
) => {
  'componentName': c.componentName,
  'variants': c.variants,
  'panelId': c.panelId,
};
Map<String, Object?> __zoomable_imageZoomableImage(
  _zoomable_image.ZoomableImage c,
) => {'src': c.src, 'alt': c.alt, 'caption': c.caption};
