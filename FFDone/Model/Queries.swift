//
//  Queries.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

extension Model {

    var allGoalsResults: ModelResults {
        return createFetchedResults(fetchReqName: "AllGoals", sortedBy: [Goal.defaultSortDescriptor])
    }

    var allIconsResults: ModelResults {
        return createFetchedResults(fetchReqName: "AllIcons", sortedBy: [Icon.defaultSortDescriptor])
    }
}

extension Goal {

    static func allMatchingGoals(model: Model, name: String) -> ModelResults {
        let nsString = name as NSString
        return model.createFetchedResults(fetchReqName: "GoalsMatching",
                                          sortedBy: [defaultSortDescriptor],
                                          substitutionVariables: ["MATCH" : nsString],
                                          sectionNameKeyPath: nil)
    }
}
