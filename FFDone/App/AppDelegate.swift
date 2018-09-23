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
    var restoreTabIndex: Int?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        ImageTransformer.install()
        ColorScheme.globalInit()
        app = App(window: window!, tabIndex: restoreTabIndex)

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

    static let archiveVersion = 1

    enum ArchiveKeys: String {
        case FF_ArchiveVersion
        case FF_TabIndex
    }

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        coder.encode(AppDelegate.archiveVersion, forKey: ArchiveKeys.FF_ArchiveVersion.rawValue)
        if let app = app {
            coder.encode(app.currentTabIndex, forKey: ArchiveKeys.FF_TabIndex.rawValue)
        }
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        let version = coder.decodeInt32(forKey: ArchiveKeys.FF_ArchiveVersion.rawValue)
        if version == AppDelegate.archiveVersion {
            restoreTabIndex = Int(coder.decodeInt32(forKey: ArchiveKeys.FF_TabIndex.rawValue))
        }
        return false
    }
}

