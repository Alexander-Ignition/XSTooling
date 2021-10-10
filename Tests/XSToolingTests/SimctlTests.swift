import XCTest
import XSTooling

final class SimctlTests: ToolTestCase {
    private var simctl: Simctl!

    override func setUp() {
        super.setUp()
        simctl = Simctl(path: path, kernel: kernel)
    }

    // MARK: - Device

    func testOpenURL() {
        XCTAssertNoThrow(try simctl.device("12").open(url: "link"))
        XCTAssertEqual(commands, ["openurl 12 link"])
    }

    func testDeviceBoot() {
        XCTAssertNoThrow(try simctl.device("a").boot())
        XCTAssertEqual(commands, ["boot a"])
    }

    // MARK: - App
}
