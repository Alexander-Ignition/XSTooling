import XCTest
import XSTooling

final class ProcessOutputErrorTests: GHTestCase {

    private var error: ProcessOutputError!
    private var result: ProcessOutput! {
        didSet { error = ProcessOutputError(output: result) }
    }

    override func setUp() {
        super.setUp()
        let command = ProcessCommand(path: "/usr/bin/bash")
        result = ProcessOutput(code: 0, reason: .exit, command: command)
    }

    func testErrorDescription() {
        result.standardError = Data("file not found\n".utf8)
        XCTAssertEqual(error.errorDescription, "file not found")
    }

    func testErrorCode() {
        result.code = 2
        XCTAssertEqual(error.errorCode, 2)
    }

    func testErrorUserInfo() {
        result.standardError = Data()
        XCTAssertEqual(error.errorUserInfo as NSDictionary, [:])

        result.standardError = Data("not found".utf8)
        XCTAssertEqual(error.errorUserInfo as NSDictionary, [
            NSLocalizedDescriptionKey: "not found"
        ])
    }
}
