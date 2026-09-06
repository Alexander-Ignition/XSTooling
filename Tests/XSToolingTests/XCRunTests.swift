#if os(macOS)

import XCTest
import XSTooling

final class XCRunTests: GHTestCase {
    private let xcrun = XCRun.current

    func testExecute() async throws {
        try await xcrun("xcodebuild", "-version").run()
    }

    func testFind() async throws {
        let path = try await xcrun.find("xcodebuild")
        XCTAssertTrue(path.hasSuffix("/usr/bin/xcodebuild"))
    }

    func testSimctl() async throws {
        let simulator = try await xcrun.simctl
        XCTAssertTrue(simulator.path.hasSuffix("/usr/bin/simctl"))
    }
}

#endif // os(macOS)
