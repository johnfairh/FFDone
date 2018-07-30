//
//  DatabaseInit.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import Yams

// Utilities to decode and populate the database with objects

private extension Dictionary where Key == String, Value == Any {
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
            icon.isDefault = (index == 0)
            icon.name = def.str("desc")
            icon.sortOrder = Int64(index)
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
            goal.completionDate = def.date("completionDate")

            let iconName = def.str("iconName")
            if !iconName.isEmpty,
                let icon = Icon.find(from: model, named: iconName) {
                goal.icon = icon
            } else {
                goal.icon = Icon.findFirst(from: model, fetchReqName: "DefaultIcons")
            }

            goal.sortOrder = Int64(index)
        }
    }

    /// Entrypoint -- create all the default objects
    static func create(model: Model, debugMode: Bool) {
        createIcons(model: model)
        if debugMode {
            createDebugGoals(model: model)
        }
    }
}
