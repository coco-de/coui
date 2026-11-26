// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:desktop_drop/desktop_drop_web.dart' as _desktop_drop_web;
import 'package:dir_picker/dir_picker.dart' as _dir_picker;
import 'package:docs_core/components/web_preview.dart' deferred as _web_preview;
import 'package:docs_site/components/chain_shuffle_control.dart'
    deferred as _chain_shuffle_control;
import 'package:docs_site/components/docs_playground.dart'
    deferred as _docs_playground;
import 'package:docs_site/components/docs_search.dart' deferred as _docs_search;
import 'package:docs_site/components/flutter_preview.dart'
    deferred as _flutter_preview;
import 'package:docs_site/components/preview_gallery.dart'
    deferred as _preview_gallery;
import 'package:docs_site/components/site_theme_controls.dart'
    deferred as _site_theme_controls;
import 'package:docs_site/components/site_theme_toggle.dart'
    deferred as _site_theme_toggle;
import 'package:file_picker_web/file_picker_web.dart' as _file_picker_web;
import 'package:file_saver_ffi/file_saver_ffi.dart' as _file_saver_ffi;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    deferred as _zoomable_image;
import 'package:url_launcher_web/url_launcher_web.dart' as _url_launcher_web;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  initialize: () {
    final Registrar registrar = webPluginRegistrar;
    _desktop_drop_web.DesktopDropWeb.registerWith(registrar);
    _dir_picker.DirPickerWeb.registerWith(registrar);
    _file_picker_web.FilePickerWeb.registerWith(registrar);
    _file_saver_ffi.FileSaverWeb.registerWith(registrar);
    _url_launcher_web.UrlLauncherPlugin.registerWith(registrar);
    registrar.registerMessageHandler();
  },
  clients: {
    'docs_core:web_preview': ClientLoader(
      (p) => _web_preview.WebPreview(
        component: p.get<String>('component'),
        variant: p.get<String?>('variant'),
        panelId: p.get<String?>('panelId'),
        chainStep: p.get<int?>('chainStep'),
      ),
      loader: _web_preview.loadLibrary,
    ),
    'chain_shuffle_control': ClientLoader(
      (p) => _chain_shuffle_control.ChainShuffleControl(
        panelId: p.get<String>('panelId'),
        component: p.get<String>('component'),
      ),
      loader: _chain_shuffle_control.loadLibrary,
    ),
    'docs_playground': ClientLoader(
      (p) => _docs_playground.DocsPlayground(
        component: p.get<String>('component'),
        panelId: p.get<String>('panelId'),
      ),
      loader: _docs_playground.loadLibrary,
    ),
    'docs_search': ClientLoader(
      (p) => _docs_search.DocsSearch(),
      loader: _docs_search.loadLibrary,
    ),
    'flutter_preview': ClientLoader(
      (p) => _flutter_preview.FlutterPreview(
        component: p.get<String>('component'),
        variant: p.get<String?>('variant'),
        panelId: p.get<String?>('panelId'),
      ),
      loader: _flutter_preview.loadLibrary,
    ),
    'preview_gallery': ClientLoader(
      (p) => _preview_gallery.PreviewGallery(
        componentName: p.get<String>('componentName'),
        variants: p.get<List<Object?>>('variants').cast<String>(),
        panelId: p.get<String>('panelId'),
      ),
      loader: _preview_gallery.loadLibrary,
    ),
    'site_theme_controls': ClientLoader(
      (p) => _site_theme_controls.SiteThemeControls(),
      loader: _site_theme_controls.loadLibrary,
    ),
    'site_theme_toggle': ClientLoader(
      (p) => _site_theme_toggle.SiteThemeToggle(),
      loader: _site_theme_toggle.loadLibrary,
    ),
    'jaspr_content:zoomable_image': ClientLoader(
      (p) => _zoomable_image.ZoomableImage(
        src: p.get<String>('src'),
        alt: p.get<String?>('alt'),
        caption: p.get<String?>('caption'),
      ),
      loader: _zoomable_image.loadLibrary,
    ),
  },
);
