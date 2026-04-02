#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_restart.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_restart'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin to restart the Flutter Engine.'
  s.description      = <<-DESC
A Flutter plugin to restart the Flutter Engine. The entry point of the Dart VM
is executed again while the underlying native application continues running.
                       DESC
  s.homepage         = 'https://github.com/your-org/native_restart'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'native_restart' => 'your@email.com' }
  s.source           = { :path => '.' }
  s.source_files = 'native_restart/Sources/native_restart/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
