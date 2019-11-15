//
//  AppDelegate.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var app: App!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        ImageTransformer.install()
        ColorScheme.globalInit()
        app = App()
        app.createScene(window: window!, state: restoredState)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        App.shared.willEnterForeground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

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
        coder.encode(AppDelegate.latestArchiveVersion, key: .FF_ArchiveVersion)
        if let app = app {
            let state = app.archiveState
            AppDelegate.archiveRules.forEach { rule in
                let value = state[keyPath: rule.keypath]
                coder.encode(value, key: rule.key)
            }
        }
        return true
    }

    var restoredState = ArchiveState()

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        let version = coder.decode(key: .FF_ArchiveVersion)

        AppDelegate.archiveRules.forEach { rule in
            if version >= rule.fromVersion {
                let value = coder.decode(key: rule.key)
                restoredState[keyPath: rule.keypath] = value
            }
        }
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
