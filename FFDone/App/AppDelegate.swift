//
//  AppDelegate.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var app: App!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ImageTransformer.install()
        ColorScheme.globalInit()
        app = App()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created -- not the very first one though.
        // Use this method to select a configuration to create the new scene with, using the stuff
        // inside `options`.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running,
        // this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: To be ported to scene-world

    static let latestArchiveVersion = 2

    enum ArchiveKey: String {
        case FF_ArchiveVersion
        case FF_TabIndex
        case FF_HomePageIndex
    }

    struct ArchiveState {
        var tabIndex: Int = 0
        var homePageIndex: Int = 0
    }

    struct ArchiveRule<T> {
        let key: ArchiveKey
        let fromVersion: Int
        let keypath: WritableKeyPath<ArchiveState, T>
        init(_ key: ArchiveKey, _ fromVersion: Int, _ keypath: WritableKeyPath<ArchiveState, T>) {
            self.key = key
            self.fromVersion = fromVersion
            self.keypath = keypath
        }
    }

    static let archiveRules = [
        ArchiveRule(.FF_TabIndex, 1, \.tabIndex),
        ArchiveRule(.FF_HomePageIndex, 2, \.homePageIndex)
    ]

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
//        coder.encode(AppDelegate.latestArchiveVersion, key: .FF_ArchiveVersion)
//        if let app = app {
//            let state = app.archiveState
//            AppDelegate.archiveRules.forEach { rule in
//                let value = state[keyPath: rule.keypath]
//                coder.encode(value, key: rule.key)
//            }
//        }
        return true
    }

    var restoredState = ArchiveState()

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
//        let version = coder.decode(key: .FF_ArchiveVersion)
//
//        AppDelegate.archiveRules.forEach { rule in
//            if version >= rule.fromVersion {
//                let value = coder.decode(key: rule.key)
//                restoredState[keyPath: rule.keypath] = value
//            }
//        }
        return false
    }
}

extension NSCoder {
    func encode(_ value: Int, key: AppDelegate.ArchiveKey) {
        encode(value, forKey: key.rawValue)
    }

    func decode(key: AppDelegate.ArchiveKey) -> Int {
        return Int(decodeInt32(forKey: key.rawValue))
    }
}
