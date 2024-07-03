//
//  App.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Top-level container for app singletons.
///
/// Most of the code here is to do with the initialization dance.
@MainActor
final class App {

    #if targetEnvironment(simulator)
    nonisolated static let debugMode = true
    #else
    nonisolated static let debugMode = false
    #endif

    // App-wide shared stuff that we own
    private let modelProvider: ModelProvider

    // App-wide shared stuff that we publish
    let importExport: AppGroupImportExport
    private(set) var alarmScheduler: AlarmScheduler!
    private(set) var tagList: TagList!
    private(set) var logCache: LogCache

    /// Model-Ready synchronization
    typealias AppReadyCallback = (Model) -> Void

    private var appReadyWaitList: [AppReadyCallback] = []

    func notifyWhenReady(_ callback: @escaping AppReadyCallback) {
        if appIsReady {
            Dispatch.toForeground {
                callback(self.modelProvider.model)
            }
        } else {
            appReadyWaitList.append(callback)
        }
    }

    // Perfect for a publisher!
    private var appIsReady = false {
        didSet {
            guard appIsReady else { return }
            while let next = appReadyWaitList.popLast() {
                Dispatch.toForeground {
                    next(self.modelProvider.model)
                }
            }
        }
    }

    init(){
        if App.debugMode {
            Log.log("App launching **** IN DEBUG MODE **** RESETTING DATABASE ***")
            Prefs.runBefore = false
        }

        modelProvider = ModelProvider(userDbName: "DataModel")
        logCache = LogCache()
        importExport = AppGroupImportExport(appGroup: "group.tml.FFDone", filePrefix: "DataModel")
        alarmScheduler = AlarmScheduler(app: self)
        tagList = TagList(app: self)
        Log.enableDebugLogs = App.debugMode

        importExport.checkForImport()

        Log.log("App.init loading model and store")
        modelProvider.load(createFreshStore: App.debugMode, storeBaseURL: importExport.groupContainerURL) {
            Task { await MainActor.run { self.initModelLoaded() } }
        }
    }

    func initModelLoaded() {
        Log.log("App.init store loaded")
        guard let model = modelProvider.model else {
            Log.fatal("Model not available")
        }

        if !Prefs.runBefore {
            DatabaseObjects.createOneTime(model: model, debugMode: App.debugMode)
        }
        DatabaseObjects.createEachTime(model: model, debugMode: App.debugMode)

        model.save {
            self.initComplete(model: model)
        }
    }

    func initComplete(model: Model) {
        Log.log("App.init complete!")
        Prefs.runBefore = true
        appIsReady = true
    }

    func willEnterForeground() {
        Log.log("App.willEnterForeground")
        alarmScheduler.willEnterForeground()
    }

    // MARK: Shared instance

    static var shared: App {
        return (UIApplication.shared.delegate as! AppDelegate).app
    }
}

/// Helper around app preferences
extension Prefs {
    static var runBefore: Bool {
        set {
            Prefs.set("RunBefore", to: newValue)
        }
        get {
            return Prefs.bool("RunBefore")
        }
    }

    static var defaultGoalIcon: String {
        set {
            Prefs.set("DefGoalIcon", to: newValue)
        }
        get {
            return Prefs.string("DefGoalIcon")
        }
    }

    static var defaultAlarmIcon: String {
        set {
            Prefs.set("DefAlarmIcon", to: newValue)
        }
        get {
            return Prefs.string("DefAlarmIcon")
        }
    }

    static var unsubbed: Bool {
        set {
            Prefs.set("Unsubbed", to: newValue)
        }
        get {
            return Prefs.bool("Unsubbed")
        }
    }

    static var subbed: Bool {
        set {
            unsubbed = !newValue
        }
        get {
            !unsubbed
        }
    }
}

struct AppGroupImportExport {
    let appGroup: String
    let filePrefix: String

    static let exportedSuffix = "exported"

    var appContainerURL: URL {
        try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    var groupContainerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            preconditionFailure("Can't get app group container URL.")
        }
        return url
    }

    private func matchingFiles(in url: URL) -> [URL] {
        var result: [URL] = []
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [], options: .skipsSubdirectoryDescendants) else {
            preconditionFailure("Can't enumerate path: \(url.path)")
        }
        while let fileURL = enumerator.nextObject() as? URL,
              case let filename = fileURL.lastPathComponent {
            if filename.hasPrefix(filePrefix) && !filename.hasSuffix(".\(Self.exportedSuffix)") {
                result.append(fileURL)
            }
        }
        return result
    }

    private func copy(fileURLs: [URL], to url: URL, suffix: String = "") {
        for fileURL in fileURLs {
            let destination = url.appendingPathComponent(fileURL.lastPathComponent)
                .appendingPathExtension(suffix)
            try? FileManager.default.removeItem(at: destination)
            try! FileManager.default.copyItem(at: fileURL, to: destination)
        }
    }

    private func delete(fileURLs: [URL]) {
        for fileURL in fileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    init(appGroup: String, filePrefix: String) {
        self.appGroup = appGroup
        self.filePrefix = filePrefix
    }

    func checkForImport() {
        Log.log("Import - app group container \(groupContainerURL.path)")
        Log.log("Import - app container \(appContainerURL.path)")
        guard case let fileURLs = matchingFiles(in: appContainerURL), !fileURLs.isEmpty else {
            Log.log("Import - no app group file import required")
            return
        }
        copy(fileURLs: fileURLs, to: groupContainerURL)
        delete(fileURLs: fileURLs)
        Log.log("Import - imported files into app group container: \(fileURLs.map(\.lastPathComponent))")
    }

    func export() {
        Log.log("Export - app group container \(groupContainerURL.path)")
        Log.log("Export - app container \(appContainerURL.path)")
        guard case let fileURLs = matchingFiles(in: groupContainerURL), !fileURLs.isEmpty else {
            Log.log("Export - no app group export required")
            return
        }
        copy(fileURLs: fileURLs, to: appContainerURL, suffix: Self.exportedSuffix)
        Log.log("Export - exported files: \(fileURLs.map(\.lastPathComponent))")
    }
}
