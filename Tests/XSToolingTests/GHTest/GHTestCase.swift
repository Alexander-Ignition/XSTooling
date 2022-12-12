//
//  GHTestCase.swift
//  
//
//  Created by Alexander Ignatiev on 12.12.2022.
//

import XCTest

class GHTestCase: XCTestCase {
    var gitHub: GHActions { .shared }

    var isLinux: Bool {
#if os(Linux)
        return true
#else
        return false
#endif
    }

#if os(Linux)

    override func recordFailure(withDescription description: String, inFile filePath: String, atLine lineNumber: Int, expected: Bool) {
        if !expected, gitHub.isEnabled {
            gitHub.error(file: filePath, line: lineNumber, message: description)
        }
        super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
    }

#else // os(Darwin)

    override func record(_ issue: XCTIssue) {
        if gitHub.isEnabled {
            if let location = issue.sourceCodeContext.location {
                gitHub.error(file: location.fileURL.absoluteString, line: location.lineNumber, message: issue.compactDescription)
            } else {
                gitHub.error(message: issue.compactDescription)
            }
        }
        super.record(issue)
    }

#endif
}