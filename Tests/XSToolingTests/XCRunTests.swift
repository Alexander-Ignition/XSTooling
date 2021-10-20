import XCTest
import XSTooling

final class XCRunTests: ToolTestCase {
    private var xcrun: XCRun!

    override func setUp() {
        super.setUp()
        xcrun = XCRun(path: path, kernel: kernel)
    }

    func testInitWithDefaults() {
        xcrun = XCRun()
        XCTAssertEqual(xcrun.path, "/usr/bin/xcrun")
        XCTAssertTrue(xcrun.kernel === Kernel.system)
    }

    func testSimctl() throws {
        output = "/text/simctl"
        let simctl = try xcrun.simctl()
        XCTAssertEqual(commands, [["--find", "simctl"]])
        XCTAssertEqual(simctl.path, "/text/simctl")
        XCTAssertTrue(xcrun.kernel === kernel)
    }
}
