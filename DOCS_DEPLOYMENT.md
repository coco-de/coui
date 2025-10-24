# CoUI Documentation Deployment Guide

This document explains how the CoUI documentation sites are built and deployed to GitHub Pages.

## 📚 Documentation Sites

CoUI provides two separate component libraries, each with its own documentation:

### 🌐 CoUI Web Documentation
- **Framework**: Jaspr (Dart for web)
- **Live Site**: [https://coco-de.github.io/coui/web/](https://coco-de.github.io/coui/web/)
- **Source**: `packages/coui_web/docs/`
- **Components**: ~60 type-safe components with Tailwind CSS styling
- **Build Command**: `dart run jaspr build`

### 📱 CoUI Flutter Documentation
- **Framework**: Flutter
- **Live Site**: [https://coco-de.github.io/coui/flutter/](https://coco-de.github.io/coui/flutter/)
- **Source**: `packages/coui_flutter/docs/`
- **Components**: 80+ cross-platform UI components
- **Build Command**: `flutter build web --release`

### 🏠 Main Landing Page
- **URL**: [https://coco-de.github.io/coui/](https://coco-de.github.io/coui/)
- **Description**: Beautiful landing page with links to both documentation sites

## 🚀 Deployment

### Automatic Deployment

The documentation is automatically deployed via GitHub Actions when:
- Changes are pushed to the `main` branch
- Changes affect `packages/coui_web/` or `packages/coui_flutter/`
- Manual workflow dispatch is triggered

**Workflow File**: `.github/workflows/deploy-docs.yml`

### Deployment Process

1. **Build CoUI Web Docs**
   - Install Dart SDK
   - Install dependencies: `dart pub get`
   - Build static site: `dart run jaspr build`
   - Output: `packages/coui_web/docs/build/jaspr/`

2. **Build CoUI Flutter Docs**
   - Install Flutter SDK (version 3.35.5)
   - Install dependencies: `flutter pub get`
   - Build web app: `flutter build web --release --base-href /flutter/`
   - Output: `packages/coui_flutter/docs/build/web/`

3. **Combine Builds**
   - Create unified `_site` directory
   - Copy CoUI Web docs to `_site/web/`
   - Copy CoUI Flutter docs to `_site/flutter/`
   - Generate landing page at `_site/index.html`

4. **Deploy to GitHub Pages**
   - Upload combined site as artifact
   - Deploy to GitHub Pages environment

## 🛠️ Local Development

### CoUI Web Docs

```bash
# Navigate to docs directory
cd packages/coui_web/docs

# Install dependencies
dart pub get

# Serve locally
dart run jaspr serve

# Visit http://localhost:8080
```

### CoUI Flutter Docs

```bash
# Navigate to docs directory
cd packages/coui_flutter/docs

# Install dependencies
flutter pub get

# Run in Chrome
flutter run -d chrome

# Or build for web
flutter build web --release
```

## 📁 Directory Structure

```
coui/
├── packages/
│   ├── coui_web/
│   │   └── docs/              # Jaspr documentation app
│   │       ├── lib/
│   │       │   └── example.dart   # Component examples
│   │       ├── web/
│   │       │   └── styles.css     # Tailwind CSS
│   │       └── pubspec.yaml
│   │
│   └── coui_flutter/
│       └── docs/              # Flutter documentation app
│           ├── lib/
│           │   ├── main.dart
│           │   └── pages/     # Component examples
│           └── pubspec.yaml
│
├── .github/
│   └── workflows/
│       └── deploy-docs.yml    # Deployment workflow
│
└── DOCS_DEPLOYMENT.md         # This file
```

## 🔧 Configuration

### GitHub Pages Settings

1. Go to repository Settings > Pages
2. Source: GitHub Actions
3. The workflow will handle deployment automatically

### Base URL Configuration

- CoUI Web: Deployed to `/web/` (root of Jaspr build)
- CoUI Flutter: Deployed to `/flutter/` (configured with `--base-href /flutter/`)
- Landing Page: Deployed to `/` (generated index.html)

## 📝 Adding New Components

### For CoUI Web

1. Implement component in `packages/coui_web/lib/src/components/`
2. Export in `packages/coui_web/lib/coui_web.dart`
3. Add example in `packages/coui_web/docs/lib/example.dart`
4. Component will be visible after deployment

### For CoUI Flutter

1. Implement component in `packages/coui_flutter/lib/src/components/`
2. Export in `packages/coui_flutter/lib/coui_flutter.dart`
3. Add example in `packages/coui_flutter/docs/lib/pages/docs/components/`
4. Add route in `packages/coui_flutter/docs/lib/main.dart`
5. Component will be visible after deployment

## 🐛 Troubleshooting

### Build Failures

If the GitHub Actions workflow fails:

1. Check the workflow logs in Actions tab
2. Verify dependencies in `pubspec.yaml`
3. Test build locally before pushing
4. Ensure all imports are correct

### Components Not Showing

If a component doesn't appear in docs:

1. Verify it's exported in the main library file
2. Check if example code is added
3. For Flutter: Verify route is added in `main.dart`
4. Clear browser cache and hard reload

### Styling Issues

If styles don't load correctly:

1. CoUI Web: Check `web/styles.css` is generated
2. CoUI Flutter: Check assets are included in `pubspec.yaml`
3. Verify Tailwind CSS build process
4. Check browser console for errors

## 🔄 Workflow Triggers

The deployment workflow can be triggered by:

1. **Automatic**: Push to `main` branch
   - Only triggers if docs-related files change
   - Paths: `packages/coui_web/**`, `packages/coui_flutter/**`

2. **Manual**: Via GitHub Actions UI
   - Navigate to Actions tab
   - Select "Deploy CoUI Docs to GitHub Pages"
   - Click "Run workflow"

## 📊 Monitoring

### Check Deployment Status

1. Go to repository Actions tab
2. Find latest "Deploy CoUI Docs to GitHub Pages" workflow
3. Check status: ✅ Success / ❌ Failed

### View Deployed Sites

- Main: https://coco-de.github.io/coui/
- Web: https://coco-de.github.io/coui/web/
- Flutter: https://coco-de.github.io/coui/flutter/

## 🔐 Permissions

The workflow requires:
- `contents: read` - Read repository contents
- `pages: write` - Deploy to GitHub Pages
- `id-token: write` - Authentication for deployment

These are configured in the workflow file.

## 📚 Resources

- [Jaspr Documentation](https://docs.page/schultek/jaspr)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

To improve documentation deployment:

1. Test changes locally first
2. Update this guide if you modify deployment process
3. Keep workflow file clean and well-commented
4. Monitor deployment times and optimize if needed

---

**Last Updated**: 2025-10-23
**Maintained By**: CoUI Team
**Status**: ✅ Fully Automated
