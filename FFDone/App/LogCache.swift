//
//  LogCache.swift
//  FFDone
//
//  Distributed under the MIT license, see LICENSE.
//

import TMLPresentation

final class LogCache: LogBuffer {
    var log = "" {
        didSet {
            refresh()
        }
    }

    var notify: ((String) -> Void)? = nil {
        didSet {
            refresh()
        }
    }

    init() {
        Log.logBuffer = self
    }

    private func refresh() {
        if let notify = notify {
            notify(log)
        }
    }

    /// Record a log line in our buffer, trim if too big, push to UI.
    func log(line: String) {
        if log.lengthOfBytes(using: .utf8) > 1024 {
            log = ""
        }
        log += "\(Date()) \(line)\n"
    }
}
