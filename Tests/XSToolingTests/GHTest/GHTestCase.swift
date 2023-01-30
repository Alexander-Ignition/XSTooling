//
//  GHTestCase.swift
//  
//
//  Created by Alexander Ignatiev on 12.12.2022.
//

import XCTest

class GHTestCase: XCTestCase {
    var github: GHActions = .shared

    var isLinux: Bool {
#if os(Linux)
        return true
#else
        return false
#endif
    }

    override func run() {
        github.group(name)
        super.run()
        github.endGroup()
    }

#if os(Linux)

    override func recordFailure(withDescription description: String, inFile filePath: String, atLine lineNumber: Int, expected: Bool) {
        if github.isEnabled {
            github.error(file: filePath, line: lineNumber, message: description)
        }
        super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
    }

#else // os(Darwin)

    override func record(_ issue: XCTIssue) {
        if github.isEnabled {
            let message = "\(self.name): \(issue.compactDescription)"
            if let location = issue.sourceCodeContext.location {
                github.error(file: location.fileURL.absoluteString, line: location.lineNumber, message: message)
            } else {
                github.error(message: message)
            }
        }
        super.record(issue)
    }

#endif
}
