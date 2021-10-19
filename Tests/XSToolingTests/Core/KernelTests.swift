import XCTest
import XSTooling

final class KernelTests: XCTestCase {

    func testLongOutput() throws {
        let simctl = try XCRun(kernel: .system.printed).simctl()
        XCTAssertNotEqual(try simctl.list().devices, [:])
    }

    func testError() {
        let shell = Shell()
        XCTAssertThrowsError(try shell.execute("xzrun"))
    }
}
