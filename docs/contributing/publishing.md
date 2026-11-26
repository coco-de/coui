# Publishing to pub.dev

CoUI publishes three packages. `coui_core` provides the shared types and
tokens. `coui_flutter` and `coui_web` use its published version.
The first Flutter release is a beta because RichEditor uses a prerelease of
`super_editor`.

| Package | Publishing tag pattern |
|---|---|
| `coui_core` | `pub-coui_core-v{{version}}` |
| `coui_flutter` | `pub-coui_flutter-v{{version}}` |
| `coui_web` | `pub-coui_web-v{{version}}` |

## Validate the release

Use a clean checkout of the commit to publish. From the repository root, run
`flutter pub get --no-example --enforce-lockfile` with the Flutter version in
[Package checks](../../.github/workflows/public-ci.yml). Review the versions
and changelogs, then inspect the archives listed by these commands.

```sh
dart pub publish --dry-run --directory packages/coui_core
dart pub publish --dry-run --directory packages/coui_flutter
dart pub publish --dry-run --directory packages/coui_web
```

The Core archive includes the library and omits the repository's Figma
exporter. The platform package archives include the library assets and
examples. The workspace test suites remain in the repository.

When updating Core, review the Core constraint in both platform packages.
Publish the Core version their manifests require before publishing either
platform package. Dart resolves both dependencies together when a consumer
installs the packages.

## Publish the first versions

The person performing the initial upload signs in to pub.dev with their
Google Account. Publish Core first and confirm that public pub resolves its
version before uploading Flutter and Web.

```sh
dart pub publish --directory packages/coui_core
dart pub publish --directory packages/coui_flutter
dart pub publish --directory packages/coui_web
```

Transfer the three packages to the team publisher, then enable GitHub Actions
publishing in each package's Admin tab. Select `coco-de/coui` and the
corresponding tag pattern from the table above. See the
[Dart publishing guide](https://dart.dev/tools/pub/publishing).

## Publish updates

Release Please manages GitHub releases and package versions. To publish a
version to pub.dev, push the corresponding `pub-*` tag for that version's
commit on `main`. The [publishing workflow](../../.github/workflows/publish.yaml)
checks the tag against the manifest and uses pub.dev's GitHub OIDC authentication.
Keep creation of `pub-*` tags restricted to release maintainers. See the
[Dart guide to automated publishing](https://dart.dev/tools/pub/automated-publishing).
