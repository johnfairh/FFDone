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
@MainActor
struct AppScene {
    private let window: UIWindow
    private let director: Director
    private let directorServices: TabbedDirectorServices<DirectorInterface>

    struct State {
        var tabIndex: Int = 0
        var homePageIndex: Int = 0
    }

    var state: State {
        State(tabIndex: directorServices.currentTabIndex,
              homePageIndex: director.homePageIndex)
    }

    init(window: UIWindow, state: State) {
        self.window = window
        director = Director(alarmScheduler: App.shared.alarmScheduler,
                            tagList: App.shared.tagList,
                            logCache: App.shared.logCache,
                            homePageIndex: state.homePageIndex)
        directorServices = TabbedDirectorServices(director: director,
                                                  window: window,
                                                  tabBarVcName: "TabBarViewController",
                                                  tabIndex: state.tabIndex)
        director.services = directorServices
    }
}
