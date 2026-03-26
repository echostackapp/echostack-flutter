import Flutter
import UIKit
import EchoStack

/// Flutter plugin bridge to native EchoStack iOS SDK.
public class EchoStackPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "echostack_plugin",
            binaryMessenger: registrar.messenger()
        )
        let instance = EchoStackPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "configure":
            let apiKey = args?["apiKey"] as? String ?? ""
            let serverURL = args?["serverURL"] as? String ?? "https://api.echostack.app"
            let logLevelStr = args?["logLevel"] as? String ?? "none"

            let logLevel: EchoStackLogLevel
            switch logLevelStr {
            case "debug": logLevel = .debug
            case "warning": logLevel = .warning
            case "error": logLevel = .error
            default: logLevel = .none
            }

            EchoStack.shared.configure(
                apiKey: apiKey,
                serverURL: serverURL,
                logLevel: logLevel
            )
            result(nil)

        case "enableAppleAdsAttribution":
            result(true)

        case "getEchoStackId":
            result(EchoStack.shared.getEchoStackId())

        case "getAttributionParams":
            result(EchoStack.shared.getAttributionParams())

        case "isSdkDisabled":
            result(EchoStack.shared.isSdkDisabled())

        case "sendEvent":
            let eventType = args?["eventType"] as? String ?? ""
            let parameters = args?["parameters"] as? [String: Any]
            EchoStack.shared.sendEvent(eventType, parameters: parameters)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
