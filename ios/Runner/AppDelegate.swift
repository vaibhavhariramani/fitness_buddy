import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "fitness_buddy/instagram_share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "shareToInstagramStories" else {
        result(FlutterMethodNotImplemented)
        return
      }
      Self.shareToInstagramStories(call: call, result: result)
    }
  }

  /// Posts an image straight to Instagram's Stories composer via its public
  /// pasteboard handoff (no Instagram API/auth involved — the same
  /// mechanism Instagram documents for third-party "share to Stories"
  /// buttons): the image goes on the pasteboard under Instagram's sticker
  /// UTI key, then `instagram-stories://share` is opened to hand off to it.
  /// Falls back to `false` (letting the caller fall back to the plain OS
  /// share sheet) when Instagram isn't installed.
  private static func shareToInstagramStories(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let args = call.arguments as? [String: Any],
      let imageData = args["image"] as? FlutterStandardTypedData,
      let url = URL(string: "instagram-stories://share")
    else {
      result(false)
      return
    }
    guard UIApplication.shared.canOpenURL(url) else {
      result(false)
      return
    }

    let pasteboardItems: [String: Any] = [
      "com.instagram.sharedSticker.backgroundImage": imageData.data
    ]
    UIPasteboard.general.setItems(
      [pasteboardItems],
      options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
    )

    UIApplication.shared.open(url, options: [:]) { success in
      result(success)
    }
  }
}
