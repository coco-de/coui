// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// The iOS half of coui_flutter: it measures the fold of a folding iPhone and
// hands it to `FoldScopeHost` (lib/src/theme/fold_scope.dart). CocoaPods
// builds the same sources from ../coui_flutter.podspec.
let package = Package(
    name: "coui_flutter",
    platforms: [
        // The lowest target the Flutter versions this package supports build
        // for. The fold APIs are checked at run time, so the plugin raises no
        // app's minimum.
        .iOS("13.0")
    ],
    products: [
        .library(name: "coui-flutter", targets: ["coui_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "coui_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                .headerSearchPath("include/coui_flutter")
            ]
        )
    ]
)
