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
}
