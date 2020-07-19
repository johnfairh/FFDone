//
//  DatabaseInit.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import Yams

// Utilities to decode and populate the database with objects

extension Dictionary where Key == String, Value == Any {
    func str(_ key: String) -> String {
        guard let value = self[key] as? String else {
            return ""
        }
        return value
    }

    func int(_ key: String) -> Int {
        guard let value = self[key] as? Int else {
            return 0
        }
        return value
    }

    func date(_ key: String) -> Date {
        guard let value = self[key] as? Date else {
            return Date()
        }
        return value
    }

    func bool(_ key: String) -> Bool {
        guard let value = self[key] as? Bool else {
            return false
        }
        return value
    }
}

/// Namespace
enum DatabaseObjects {

    /// Grab a yaml file and decode it
    private static func readYaml(file: String) -> [[String: Any]] {
        guard let pathname = Bundle.main.path(forResource: file, ofType: "yaml"),
            let contents = try? String(contentsOfFile: pathname) else {
                Log.log("Can't load \(file).yaml in the main bundle")
                return []
        }

        do {
            guard let defs = try Yams.load(yaml: contents) as? [[String: Any]] else {
                Log.log("Couldn't decode yaml from \(file).yaml")
                return []
            }
            return defs
        } catch {
            Log.log("Really couldn't decode yaml from \(file).yaml: \(error)")
            return []
        }
    }

    /// Set up the built-in icons
    private static func createIcons(model: Model) {
        let defs = readYaml(file: "DefaultIcons")

        for (index, def) in defs.enumerated() {

            let assetName = "DefGoal_\(def.str("name"))"

            guard let image = UIImage(named: assetName) else {
                Log.log("Can't find default image \(assetName)")
                continue
            }

            let icon = Icon.create(from: model)

            icon.nativeImage = image
            icon.isBuiltin = true
            icon.name = def.str("desc")
            icon.sortOrder = Int64(index)
        }
    }

    private static func createMissingIcons(model: Model) {
        let defs = readYaml(file: "DefaultIcons")

        defs.forEach { def in
            let name = def.str("desc")
            guard Icon.find(from: model, named: name) == nil else {
                Log.log("Skipping \(name) - already exists")
                return
            }

            let assetName = "DefGoal_\(def.str("name"))"
            guard let image = UIImage(named: assetName) else {
                Log.log("Can't find default image \(assetName)")
                return
            }

            let icon = Icon.createWithDefaults(model: model)
            icon.nativeImage = image
            icon.name = name
        }
    }

    /// Create the debug goals from the yaml file
    private static func createDebugGoals(model: Model) {
        let defs = readYaml(file: "DebugGoals")

        for (index, def) in defs.enumerated() {

            let goal = Goal.create(from: model)

            goal.name = def.str("name")
            goal.currentSteps = def.int("currentSteps")
            goal.totalSteps = def.int("totalSteps")
            goal.creationDate = def.date("creationDate")
            if goal.isComplete {
                goal.completionDate = def.date("completionDate")
            } else {
                goal.completionDate = Goal.incompleteDate
            }
            goal.isFav = def.bool("fav")

            let iconName = def.str("iconName")
            if !iconName.isEmpty,
                let icon = Icon.find(from: model, named: iconName) {
                goal.icon = icon
            } else {
                goal.icon = Icon.getGoalDefault(model: model)
            }

            let yamlSortOrder = def.int("sortOrder")
            if yamlSortOrder == 0 {
                goal.sortOrder = Int64(index)
            } else {
                goal.sortOrder = Int64(yamlSortOrder)
            }

            let tag = def.str("tag")
            if !tag.isEmpty {
                goal.tag = tag
            }
        }
    }

    /// Create the debug notes from the yaml file
    private static func createDebugNotes(model: Model) {
        let defs = readYaml(file: "DebugNotes")

        defs.forEach { def in
            let goalName = def.str("goal")
            guard let goal = Goal.find(from: model, named: goalName) else {
                Log.log("Debug load failed, can't find goal for note \(goalName)")
                return
            }

            let note = Note.create(from: model)
            note.text = def.str("text")
            note.goal = goal
            note.creationDate = def.date("creationDate")
        }
    }

    /// Create the debug alarms from the yaml file
    private static func createDebugAlarms(model: Model) {
        let defs = readYaml(file: "DebugAlarms")

        for (index, def) in defs.enumerated() {
            let name = def.str("name")

            let iconName = def.str("iconName")
            guard let icon = Icon.find(from: model, named: iconName) else {
                Log.log("Debug load failed, can't find icon for alert \(name)")
                return
            }

            let alarm = Alarm.create(from: model)
            alarm.name = name
            alarm.icon = icon
            alarm.cdType = Int16(def.int("kind"))
            let day = def.int("day")
            alarm.cdWeekDay = Int16((day == 0) ? 1 : day)
            alarm.sortOrder = Int64(index)
            do {
                let note = Note.createWithDefaults(model: model)
                note.text = def.str("defaultNote")
                alarm.defaultNote = note
            }

            do {
                let note = Note.createWithDefaults(model: model)
                note.text = def.str("activeNote")
                alarm.activeNote = note
            }

            if def.bool("active") {
                alarm.activate()
            } else {
                alarm.deactivate()
            }
        }
    }

    /// Create debug epochs
    static func createDebugEpochs(model: Model) {
        let defs = readYaml(file: "DebugEpochs")

        if let def = defs.first {
            let epoch = Epoch.create(model: model,
                                     shortName: def.str("shortname"),
                                     longName: def.str("longname"),
                                     majorVersion: def.int("majorversion"),
                                     minorVersion: def.int("minorversion"))
            epoch.startDate = def.date("startDate")
        }
    }

    /// Create the icon source templates from the yaml file
    private static func createIconSources() {
        let defs = readYaml(file: "DefaultIconSources")

        defs.forEach {
            IconSourceBuilder.activateSource(name: $0.str("name"))
        }
    }

    private static func createAlarmKinds() {
        let defs = readYaml(file: "DefaultAlarmKinds")
        defs.forEach {
            if let alarmSet = AlarmSet(rawValue: $0.str("name")) {
                AlarmSet.shared = alarmSet
            }
        }
    }

    static func readTweaks() -> [String: Any]? {
        readYaml(file: "DefaultTweaks").first
    }

    /// Create the global epoch we rely on having
    static func createGlobalEpoch(model: Model) {
        let epoch = Epoch.createGlobal(model: model, longName: Tweaks.shared.globalEpochName)
        Log.assert(epoch.sortOrder == 1)
    }

    /// Entrypoint -- create all the default objects, called only on first run
    static func createOneTime(model: Model, debugMode: Bool) {
        createIcons(model: model)
        createGlobalEpoch(model: model)
        if debugMode {
            createDebugGoals(model: model)
            model.saveAndWait()
            createDebugNotes(model: model)
            createDebugAlarms(model: model)
            createDebugEpochs(model: model)
        }
    }

    /// Entrypoint -- create objects etc. on every run
    static func createEachTime(model: Model, debugMode: Bool) {
        createIconSources()
        createAlarmKinds()
        #if false
        createMissingIcons(model: model)
        #endif
    }
}
