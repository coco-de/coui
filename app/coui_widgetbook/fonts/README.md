# Widgetbook fonts

These static Pretendard files are byte-identical copies of the masters in
`docs_site/fonts/`, matching the native `app/docs_app/fonts/` bundle. Keep the
copies and the `pubspec.yaml` weight declarations together when updating the
masters.

The mono face is not copied here. Code roles name `Geist Mono`, and
`coui_flutter` bundles the `GeistMono` masters that Flutter reaches through the
role's fallback, so another copy would only add bytes the web build downloads
before its first frame.

They live inside this app because `../../docs_site/fonts/` asset keys would
escape the deployed `/widgetbook/assets/` URL and fail to load in a browser.
The catalog smoke test loads the shipped font manifest, and the web-build check
should verify that every manifest asset exists inside `build/web/assets/`.
