import Flutter
import UIKit
import receive_sharing_intent

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    handleInitialSharingIntent(from: connectionOptions)
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if URLContexts.contains(where: handleSharingIntent) {
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  private func handleInitialSharingIntent(from connectionOptions: UIScene.ConnectionOptions) {
    let sharingIntent = SwiftReceiveSharingIntentPlugin.instance

    for context in connectionOptions.urlContexts where sharingIntent.hasMatchingSchemePrefix(url: context.url) {
      let launchOptions: [AnyHashable: Any] = [UIApplication.LaunchOptionsKey.url: context.url]
      _ = sharingIntent.application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)
      return
    }

    for userActivity in connectionOptions.userActivities {
      if sharingIntent.application(UIApplication.shared, continue: userActivity, restorationHandler: { _ in }) {
        return
      }
    }
  }

  private func handleSharingIntent(_ context: UIOpenURLContext) -> Bool {
    let sharingIntent = SwiftReceiveSharingIntentPlugin.instance
    guard sharingIntent.hasMatchingSchemePrefix(url: context.url) else {
      return false
    }

    var options: [UIApplication.OpenURLOptionsKey: Any] = [
      .openInPlace: context.options.openInPlace
    ]
    if let sourceApplication = context.options.sourceApplication {
      options[.sourceApplication] = sourceApplication
    }
    if let annotation = context.options.annotation {
      options[.annotation] = annotation
    }

    return sharingIntent.application(UIApplication.shared, open: context.url, options: options)
  }
}
