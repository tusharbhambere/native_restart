import Flutter
import UIKit
import native_restart

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        // Register the restart callback — called with the NEW engine after
        // each restart so plugins are registered on the correct engine.
        RestartPlugin.restartPluginRegistrantCallback = { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
        // Register plugins on the initial implicit engine.
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
