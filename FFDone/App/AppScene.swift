//
//  AppScene.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

///
/// Per-window (per-scene) user-interface object
///
struct AppScene {
    private let window: UIWindow
    private let director: Director
    private let directorServices: TabbedDirectorServices<DirectorInterface>

    init(window: UIWindow) {
        self.window = window
        director = Director(alarmScheduler: App.shared.alarmScheduler,
                            tagList: App.shared.tagList,
                            logCache: App.shared.logCache,
                            homePageIndex: 0 /*state.homePageIndex*/)
        directorServices = TabbedDirectorServices(director: director,
                                                  window: window,
                                                  tabBarVcName: "TabBarViewController",
                                                  tabIndex: 0/*state.tabIndex*/)
        director.services = directorServices
    }
}
