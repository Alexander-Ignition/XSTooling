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
        if gitHub.isEnabled {
            gitHub.error(file: filePath, line: lineNumber, message: description)
        }
        super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
    }

#endif
}
