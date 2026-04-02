# native_restart

A Flutter plugin to restart the Flutter Engine.

The plugin works by creating a new instance of the Flutter Engine. The entry point of the Dart VM is executed again, while the underlying platform specific application keeps running. This is achieved as follows:

### Android

Recreating the `FlutterActivity`.

### iOS

Creating a new `FlutterEngine` and `FlutterViewController`, then setting it as the root view controller of the active window. Supports both the traditional **AppDelegate** lifecycle and the newer **UISceneDelegate** lifecycle (iOS 13+).

## Installation

Add package to the dependencies section of the `pubspec.yaml`:

```yaml
dependencies:
  native_restart: ^1.0.0
```

## Documentation

A single method call allows to terminate the Dart VM & restart execution from the entry point.

```dart
import 'package:native_restart/native_restart.dart';

// 🎉
restart();
```

You can also pass arguments to the new Dart entry point:

```dart
restart(args: ['--route', '/home']);

// In main():
void main(List<String> args) {
  print(args); // ['--route', '/home']
}
```

## Setup

### Android

Modify the `MainActivity.kt` file in your Flutter project as follows:

```diff
+import android.content.Context
+import io.native_restart.RestartPlugin
 import io.flutter.embedding.android.FlutterActivity

-class MainActivity: FlutterActivity()
+class MainActivity: FlutterActivity() {
+    override fun provideFlutterEngine(context: Context) = RestartPlugin.provideFlutterEngine()
+}
```

### iOS

#### UISceneDelegate lifecycle (recommended, required for iOS 26+)

This is the recommended setup for new projects and for projects migrated to the UIScene lifecycle.

**1. Modify `AppDelegate.swift`:**

```diff
 import Flutter
 import UIKit
+import native_restart

 @main
 @objc class AppDelegate: FlutterAppDelegate {
     override func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
+        RestartPlugin.restartPluginRegistrantCallback = { registry in
+            GeneratedPluginRegistrant.register(with: registry)
+        }
         GeneratedPluginRegistrant.register(with: self)
         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
 }
```

**2. Add `UIApplicationSceneManifest` to `Info.plist`:**

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneClassName</key>
                <string>UIWindowScene</string>
                <key>UISceneDelegateClassName</key>
                <string>FlutterSceneDelegate</string>
                <key>UISceneConfigurationName</key>
                <string>flutter</string>
                <key>UISceneStoryboardFile</key>
                <string>Main</string>
            </dict>
        </array>
    </dict>
</dict>
```

> If your project was auto-migrated by `flutter run` (Flutter 3.41+), this manifest is already added for you.

#### Legacy AppDelegate lifecycle

If your project has **not** migrated to the UIScene lifecycle, use the legacy callback instead:

```diff
 import Flutter
 import UIKit
+import native_restart

 @UIApplicationMain
 @objc class AppDelegate: FlutterAppDelegate {
     override func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
+        RestartPlugin.generatedPluginRegistrantRegisterCallback = { [weak self] in
+            GeneratedPluginRegistrant.register(with: self!)
+        }
         GeneratedPluginRegistrant.register(with: self)
         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
 }
```

> **Note:** `restartPluginRegistrantCallback` (engine-aware) takes priority over `generatedPluginRegistrantRegisterCallback` (legacy) when both are set. The engine-aware callback is preferred because it registers plugins on the **new** engine instance rather than the original AppDelegate.
