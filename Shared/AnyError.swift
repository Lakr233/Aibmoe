//
//  AnyError.swift
//  Aibmoe
//
//  Created by Rachel on 2021/12/27.
//

import Foundation

enum AnyError: LocalizedError {
    case error(_ error: Error)
    case localizedError(_ error: LocalizedError)

    static func anyError(_ error: Error) -> AnyError {
        if let error = error as? LocalizedError {
            return .localizedError(error)
        } else {
            return .error(error)
        }
    }

    /// A localized message describing what error occurred.
    var errorDescription: String? {
        switch self {
        case .localizedError(let error):
            return error.errorDescription
        case .error(let error):
            return "\(error)"
        }
    }

    /// A localized message describing the reason for the failure.
    var failureReason: String? {
        switch self {
        case .localizedError(let error):
            return error.failureReason
        case .error(let error):
            return "\(error)"
        }
    }

    /// A localized message describing how one might recover from the failure.
    var recoverySuggestion: String? {
        switch self {
        case .localizedError(let error):
            return error.recoverySuggestion
        case .error(let error):
            return "\(error)"
        }
    }

    /// A localized message providing "help" text if the user requests help.
    var helpAnchor: String? {
        switch self {
        case .localizedError(let error):
            return error.helpAnchor
        case .error(let error):
            return "\(error)"
        }
    }
}
