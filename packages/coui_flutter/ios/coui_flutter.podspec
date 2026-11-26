#
# The iOS half of coui_flutter: it measures the fold of a folding iPhone and
# hands it to `FoldScopeHost` (lib/src/theme/fold_scope.dart). Everything
# else in the package is Dart.
#
# CocoaPods reads this file; Swift Package Manager reads
# coui_flutter/Package.swift. Both build the same sources.
#
Pod::Spec.new do |s|
  s.name             = 'coui_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Measures the fold of a folding iPhone for coui_flutter.'
  s.description      = <<-DESC
Reads where the system reserves a division of the Flutter view and how far the
hinge is open, with the public UIKit APIs of the iOS 27.1 SDK. On an SDK or an
OS without them it reports no fold.
                       DESC
  s.homepage         = 'https://github.com/coco-de/coui'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Cocode'
  s.source           = { :path => '.' }
  s.source_files = 'coui_flutter/Sources/coui_flutter/**/*.{h,m}'
  s.public_header_files = 'coui_flutter/Sources/coui_flutter/include/**/*.h'
  s.dependency 'Flutter'
  # The lowest target the Flutter versions this package supports build for.
  # The fold APIs are checked at run time, so the plugin raises no app's
  # minimum.
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  s.resource_bundles = {'coui_flutter_privacy' => ['coui_flutter/Sources/coui_flutter/PrivacyInfo.xcprivacy']}
end
