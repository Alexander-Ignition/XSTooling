import XCTest
import XSTooling

extension ProcessCommand {
    var assert: Assertion { Assertion(command: self) }

    struct Assertion {
        private let command: ProcessCommand

        fileprivate init(command: ProcessCommand) {
            self.command = command
        }

        func equal(path: String, arguments: String..., file: StaticString = #filePath, line: UInt = #line) {
            let other = ProcessCommand(path: path, arguments: arguments)
            equal(to: other, file: file, line: line)
        }

        func equal(to other: ProcessCommand, file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertEqual(command.executableURL, other.executableURL, "executableURL", file: file, line: line)
            XCTAssertEqual(command.arguments, other.arguments, "arguments", file: file, line: line)
            XCTAssertEqual(command.environment, other.environment, "environment", file: file, line: line)
            XCTAssertEqual(command.currentDirectoryURL, other.currentDirectoryURL, "currentDirectoryURL", file: file, line: line)
            XCTAssertEqual(command.successCode, other.successCode, "successCode", file: file, line: line)
        }
    }
}
