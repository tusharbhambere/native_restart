import Flutter
import UIKit

public class RestartPlugin: NSObject, FlutterPlugin {

    // MARK: - Plugin Registration Callbacks

    /// Engine-based callback (recommended). Called with the **new** engine after
    /// restart so that plugins are registered on the correct engine instance.
    /// When set, this takes priority over `generatedPluginRegistrantRegisterCallback`.
    ///
    /// Usage:
    /// ```swift
    /// RestartPlugin.restartPluginRegistrantCallback = { registry in
    ///     GeneratedPluginRegistrant.register(with: registry)
    /// }
    /// ```
    @objc public static var restartPluginRegistrantCallback: ((FlutterPluginRegistry) -> Void)?

    /// Legacy callback kept for backward compatibility with AppDelegate-based apps.
    /// Ignored when `restartPluginRegistrantCallback` is set.
    @objc public static var generatedPluginRegistrantRegisterCallback: () -> Void = {
        NSLog("WARNING: generatedPluginRegistrantRegisterCallback is not assigned by the AppDelegate.")
    }

    // MARK: - Private

    /// Strong reference to the engine created during restart.
    private static var currentEngine: FlutterEngine?

    /// Cached window so rapid restarts always find it even when the old VC is
    /// mid-teardown and scene queries momentarily fail.
    private static weak var cachedWindow: UIWindow?

    /// Guard against overlapping restart calls.
    private static var isRestarting = false

    /// Counter for unique engine names.
    private static var restartCount: Int = 0

    private weak var registrar: FlutterPluginRegistrar?

    // MARK: - FlutterPlugin

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "native_restart/engine",
            binaryMessenger: registrar.messenger()
        )
        let instance = RestartPlugin()
        instance.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        switch call.method {
        case "restart":
            let args = arguments?["args"] as? [String]
            let savedRegistrar = self.registrar

            // Reply BEFORE tearing down the current engine.
            result(nil)

            // Perform the actual restart on the next run-loop turn.
            DispatchQueue.main.async {
                Self.performRestart(args: args, registrar: savedRegistrar)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Restart Logic

    private static func performRestart(args: [String]?, registrar: FlutterPluginRegistrar?) {
        // Prevent overlapping restarts — drop rapid-fire duplicates.
        guard !isRestarting else { return }
        isRestarting = true

        guard let window = resolveWindow(registrar: registrar) else {
            NSLog("RestartPlugin: Could not find an active window to host the restarted Flutter engine.")
            isRestarting = false
            return
        }

        let oldEngine = currentEngine

        restartCount += 1
        let engine = FlutterEngine(name: "io.flutter.restart.\(restartCount)")
        engine.run(
            withEntrypoint: nil,
            libraryURI: nil,
            initialRoute: nil,
            entrypointArgs: args
        )

        // Register plugins on the *new* engine BEFORE attaching the VC.
        // This ensures that any plugin method calls made early in main()
        // are already routable when the Dart isolate begins executing.
        if let callback = restartPluginRegistrantCallback {
            callback(engine)
        } else {
            generatedPluginRegistrantRegisterCallback()
        }

        let viewController = FlutterViewController(
            engine: engine,
            nibName: nil,
            bundle: nil
        )

        // Hold a strong reference BEFORE swapping the root VC.
        currentEngine = engine

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        // Let the old engine be released.
        _ = oldEngine

        // Allow the next restart after the current run-loop turn completes,
        // giving UIKit time to finish the VC transition.
        DispatchQueue.main.async {
            isRestarting = false
        }
    }

    // MARK: - Window Discovery

    /// Returns (and caches) the window to use for restart.
    private static func resolveWindow(registrar: FlutterPluginRegistrar?) -> UIWindow? {
        // Try the cached window first — it survives VC swaps.
        if let w = cachedWindow, w.windowScene != nil {
            return w
        }

        // Discover it freshly, then cache.
        if let w = findActiveWindow(registrar: registrar) {
            cachedWindow = w
            return w
        }

        return nil
    }

    private static func findActiveWindow(registrar: FlutterPluginRegistrar?) -> UIWindow? {
        // 1. From the registrar's view controller.
        if let window = registrar?.viewController?.view?.window {
            return window
        }

        // 2. Scene-based discovery (iOS 13+).
        if #available(iOS 13.0, *) {
            let windowScenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }

            let active = windowScenes.filter { $0.activationState == .foregroundActive }

            if let window = keyWindow(from: active) ?? keyWindow(from: windowScenes) {
                return window
            }
        }

        // 3. Legacy fallback.
        if let window = UIApplication.shared.delegate?.window {
            return window
        }

        return nil
    }

    @available(iOS 13.0, *)
    private static func keyWindow(from scenes: [UIWindowScene]) -> UIWindow? {
        for scene in scenes {
            if #available(iOS 15.0, *) {
                if let kw = scene.keyWindow { return kw }
            }
            if let kw = scene.windows.first(where: { $0.isKeyWindow }) {
                return kw
            }
            if let first = scene.windows.first {
                return first
            }
        }
        return nil
    }
}

