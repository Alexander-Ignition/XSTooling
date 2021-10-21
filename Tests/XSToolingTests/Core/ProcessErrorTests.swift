import XCTest
import XSTooling

final class ProcessErrorTests: XCTestCase {

    func testString() {
        let error = ProcessError(
            status: 1,
            reason: .exit,
            data: Data("Oops!".utf8))

        XCTAssertEqual(error.string, "Oops!")
    }

    func testExitDescription() {
        let error = ProcessError(
            status: 2,
            reason: .exit,
            data: Data("file not found".utf8))

        XCTAssertEqual("\(error)", "file not found")
    }
}
