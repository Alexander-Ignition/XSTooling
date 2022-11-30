import XCTest
import XSTooling

#if os(macOS)

final class XCRunTests: XCTestCase {
    private var xcrun: XCRun!
    private var path: String!

    override func setUp() {
        super.setUp()
        path = "/usr/bin/xcrun/\(name)"
        xcrun = XCRun(path: path)
    }

    func testExecute() async {
        do {
            xcrun = XCRun()
            try await xcrun.command.appending(arguments: "xcodebuild", "-version").run()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFind() {
        let command = xcrun.find("swift")

        command.assert.equal(path: path, arguments: "--find", "swift")
    }

    func testSimctl() {
        let simctl = xcrun.simctl

        simctl.command.assert.equal(path: path, arguments: "simctl")
    }
}

#endif
