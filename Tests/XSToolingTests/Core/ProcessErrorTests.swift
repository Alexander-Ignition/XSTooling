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
            data: Data("a".utf8))

        XCTAssertEqual("\(error)", "exit: 2, a")
    }

    func testUncaughtSignalDescription() {
        let error = ProcessError(
            status: 3,
            reason: .uncaughtSignal,
            data: Data("b".utf8))

        XCTAssertEqual("\(error)", "uncaught signal: 3, b")
    }
}
