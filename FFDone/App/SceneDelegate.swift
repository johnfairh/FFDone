//
//  SceneDelegate.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface to UIKit Scene Management
///
/// 1:1 SceneDelegate <-> AppScene <-> Director
///
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appScene: AppScene?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let window = window else { return }
        var appSceneState = AppScene.State()

        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity,
            userActivity.activityType == Strings.UserActivityType.stateRestoration {
            decode(activity: userActivity, to: &appSceneState)
        }

        appScene = AppScene(window: window, state: appSceneState)
    }

    /// Save away high-level scene state for later restoration
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
         guard let appScene = appScene else { return nil }

         let activity = NSUserActivity(activityType: Strings.UserActivityType.stateRestoration)
         activity.title = "FFDone"
         let userInfo = encode(sceneState: appScene.state)
         activity.addUserInfoEntries(from: userInfo)
         return activity
     }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        App.shared.willEnterForeground()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

// MARK: AppScene State Save and Restoration Gubbins

fileprivate let latestStateRestorationVersion = 1

fileprivate enum SceneStateKey: String {
    case version
    case tabIndex
    case homePageIndex
}

fileprivate struct SceneStateRule<T> {
    let key: SceneStateKey
    let fromVersion: Int
    let keyPath: WritableKeyPath<AppScene.State, T>
    init(_ key: SceneStateKey, _ fromVersion: Int, _ keypath: WritableKeyPath<AppScene.State, T>) {
        self.key = key
        self.fromVersion = fromVersion
        self.keyPath = keypath
    }
}

fileprivate let sceneStateRules = [
    SceneStateRule(.tabIndex, 1, \.tabIndex),
    SceneStateRule(.homePageIndex, 1, \.homePageIndex)
]

fileprivate func encode(sceneState: AppScene.State) -> [String : Any] {
    var dict: [String : Any] = [:]
    dict[SceneStateKey.version.rawValue] = latestStateRestorationVersion
    sceneStateRules.forEach { r in
        dict[r.key.rawValue] = sceneState[keyPath: r.keyPath]
    }
    return dict
}

fileprivate func decode(activity: NSUserActivity, to sceneState: inout AppScene.State) {
    guard let userInfo = activity.userInfo else { return }
    let version = userInfo[SceneStateKey.version.rawValue] as? Int ?? 0
    sceneStateRules.forEach { r in
        if version >= r.fromVersion {
            if let value = userInfo[r.key.rawValue] as? Int {
                sceneState[keyPath: r.keyPath] = value
            }
        }
    }
}
