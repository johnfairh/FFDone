//
//  DebugInit.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation
import Yams

// Utilities to decode and populate the database with sample objects

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
}

/// Namespace
enum DebugObjects {

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

    /// Create the debug goals from the yaml file
    private static func initGoals(model: Model) {
        let defs = readYaml(file: "DebugGoals")

        for (index, def) in defs.enumerated() {

            let goal = Goal.create(from: model)

            goal.name = def.str("name")
            goal.currentSteps = def.int("currentSteps")
            goal.totalSteps = def.int("totalSteps")
            goal.creationDate = def.date("creationDate")
            goal.completionDate = def.date("completionDate")

            goal.sortOrder = Int64(index)
        }
    }

    /// Entrypoint -- create all the debug objects
    static func create(model: Model) {
        initGoals(model: model)
    }
}
