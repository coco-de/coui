<div align="center">

# 🎨 coui_flutter

**Beautifully designed components from coui/ui, now available for Flutter**

[![GitHub Sponsors](https://img.shields.io/github/sponsors/coco-de?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/coco-de)
[![GitHub Repo stars](https://img.shields.io/github/stars/coco-de/coui?style=for-the-badge&logo=github&logoColor=white)](https://github.com/coco-de/coui)

---

🚀 A comprehensive Flutter UI library inspired by coui/ui, providing elegant and customizable components for modern app development.

**[📚 Component Catalog](https://coui.cocode.im/)** • **[💬 Discussions](https://github.com/coco-de/coui/discussions)**

</div>

> [!WARNING]
> **Experimental** — Public APIs may change before `1.0.0`. See the [deprecation policy](https://github.com/coco-de/coui/blob/main/docs/contributing/upgrading.md#deprecation) and changelog before upgrading.

## Installation

```sh
flutter pub add 'coui_flutter:^0.194.2-beta.1'
```

The package selects a compatible version of `coui_core` through pub. The
[getting started guide](https://coui.cocode.im/getting-started) shows how to
mount `CoUIApp` and render your first component.

## ✨ Features

- 🎨 **70+ Beautiful Components** - From basic buttons to complex data tables
- 🌙 **Dark/Light Mode** - Built-in theme switching with multiple color schemes  
- 📱 **Responsive Design** - Components that work seamlessly across all screen sizes
- 🎯 **Type Safe** - Full TypeScript-like experience with Dart's strong typing
- 🚀 **Performance First** - Optimized components for smooth animations and interactions
- 🎨 **Customizable** - Easy theming and styling to match your brand
- 📦 **Tree Shakable** - Import only what you need

## 🧩 Components Library

**161 component contracts, implemented on both Flutter and Web** with the same
parameter names. `tool/api_sync_check.dart` gates that in CI, so neither platform
can quietly fall behind.

Browse every component — rendered live, Flutter and Web side by side — at
**[coui.cocode.im](https://coui.cocode.im/)**.

The list is not duplicated here on purpose. The screenshot grid that used to sit in
this spot pointed at a repository path and a docs host that no longer exist, and it
advertised components (`Sheet`, `Input`, `Switch`, `TabList`) that this package does
not ship. A copied list stops matching the code and then misleads.

## 🤝 Contributing & Support

We welcome contributions from the community! Here's how you can help make coui_flutter even better:

### 🌟 Ways to Contribute

<div align="center">

[![⭐ Star on GitHub](https://img.shields.io/badge/⭐_Star_on_GitHub-black?style=for-the-badge&logo=github)](https://github.com/coco-de/coui)
[![💖 Sponsor](https://img.shields.io/badge/💖_Sponsor-pink?style=for-the-badge&logo=github-sponsors)](https://github.com/sponsors/coco-de)
[![🐛 Report Bug](https://img.shields.io/badge/🐛_Report_Bug-red?style=for-the-badge&logo=github)](https://github.com/coco-de/coui/issues)
[![💡 Request Feature](https://img.shields.io/badge/💡_Request_Feature-blue?style=for-the-badge&logo=github)](https://github.com/coco-de/coui/issues)

</div>

#### 💰 Financial Support
- 💖 **[GitHub Sponsors](https://github.com/sponsors/coco-de)** - Support ongoing development
- ⭐ **Star the repository** - Help us reach more developers
- 📢 **Share the project** - Spread the word in your community

#### 🛠️ Code Contributions
- 🐛 **Bug fixes** - Help us squash those pesky bugs
- ✨ **New features** - Add components or enhance existing ones
- 📚 **Documentation** - Improve guides, examples, and API docs
- 🧪 **Testing** - Write tests to improve reliability

#### 🗨️ Community Support
- 💬 **[GitHub Discussions](https://github.com/coco-de/coui/discussions)** - Ask questions and share what you build
- 🤝 **Help others** - Answer questions and share your knowledge
- 📝 **Write tutorials** - Create blog posts or video tutorials

### 🏆 Recognition

This project is funded and maintained by the community. Every contribution, no matter how small, makes a difference and helps ensure the continued development of coui_flutter.

**Thank you to all our contributors and supporters! 🙏**

---

<div align="center">

**Built and maintained by [Cocode Inc.](https://cocode.im)**

</div>

---

## Credits

CoUI Flutter's component taxonomy, public API surface, and portions of its
documentation comments originate from
[shadcn_flutter](https://github.com/sunarya-thito/shadcn_flutter)
by Thito Yalasatria Sunarya, licensed under the BSD 3-Clause License.
The implementations here have largely been rewritten.

See [`NOTICE`](../../NOTICE) at the repository root for full attribution.
