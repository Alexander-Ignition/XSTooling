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
        XCTAssertNoThrow(try simctl.device("0").open(url: "link"))
        XCTAssertEqual(commands, [["openurl", "0", "link"]])
    }

    func testDeviceBoot() {
        XCTAssertNoThrow(try simctl.device("2").boot())
        XCTAssertEqual(commands, [["boot", "2"]])
    }

    // MARK: - App
}
