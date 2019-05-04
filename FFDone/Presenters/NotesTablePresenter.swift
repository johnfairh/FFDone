//
//  NotesTablePresenter.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

/// Interface from the Notes Table VC to presenter -- requirements unique to notes table.
protocol NotesTablePresenterInterface: TablePresenterInterface {
    func selectNote(_ note: Note)
    func deleteNote(_ note: Note)

    func updateSearchResults(text: String)
    func reverseNoteOrder()

    func sectionIndexFor(date: Date) -> Int
}

// MARK: - Presenter

class NotesTablePresenter: TablePresenter<DirectorInterface>, Presenter, NotesTablePresenterInterface {
    typealias ViewInterfaceType = NotesTablePresenter//Interface --- XXX weird swift generics vs. protocols runtime crash workaround XXX

    private let selectedCallback: PresenterDone<Note>

    required init(director: DirectorInterface, model: Model, object: ModelResultsSet?, mode: PresenterMode, dismiss: @escaping PresenterDone<Note>) {
        self.selectedCallback = dismiss
        super.init(director: director, model: model, object: object, mode: mode)
    }

    func selectNote(_ note: Note) {
        selectedCallback(note)
    }

    func deleteNote(_ note: Note) {
        note.delete(from: model)
        model.save()
    }

    // MARK: - Search

    func updateSearchResults(text: String) {
        handleSearchUpdate(text: text, type: 0) { text, typeInt in
            return Note.searchByTextSortedResultsSet(model: self.model, str: text)
        }
    }

    // MARK: - Reverse button, luckily inaccessible in search mode!

    func reverseNoteOrder() {
        if filteredResults != nil {
            filteredResults = nil
        } else {
            filteredResults = Note.allReverseSortedResultsSet(model: model)
        }
    }

    /// Normally table is old->new.  Reversed means new->old, newest at the top.
    private var isReverseOrder: Bool {
        return filteredResults != nil
    }

    // MARK: - Jump-to-date

    func sectionIndexFor(date: Date) -> Int {
        guard let sections = currentResults.sections,
            sections.count > 1 else {
                return 0
        }

        let dayStamp = Note.dateToDayStamp(date: date)
        Log.log("Searching for dayStamp \(dayStamp)")

        // Binary search through the sections.
        var lower = 0
        var upper = sections.count - 1

        while upper > lower {
            let mid = (upper + lower) / 2
            let midStamp = sections[mid].name
            Log.log(" Trying \(midStamp) index \(mid)")
            switch midStamp.compare(dayStamp) {
            case .orderedAscending:
                if !isReverseOrder {
                    Log.debugLog("  Try smaller than sought, !reversed, going up")
                    lower = mid + 1
                } else {
                    Log.debugLog("  Try smaller than sought, reversed, going down")
                    upper = mid - 1
                }
            case .orderedDescending:
                if !isReverseOrder {
                    Log.debugLog("  Try bigger than sought, !reversed, going down")
                    upper = mid - 1
                } else {
                    Log.debugLog("  Try bigger than sought, reversed, going up")
                    lower = mid + 1
                }
            case .orderedSame:
                Log.debugLog("  Found it, stopping")
                upper = mid
                lower = mid
            }
        }
        let result = max(upper, 0)
        Log.log("Finished: index \(result) value \(sections[result].name)")

        return result
    }
}
