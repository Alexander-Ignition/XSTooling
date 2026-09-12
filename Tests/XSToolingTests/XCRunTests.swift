#if os(macOS)

import Testing
import XSTooling

@Suite(.gitHub)
struct XCRunTests {
    private let xcrun = XCRun.current

    @Test func run() async {
        await #expect(throws: Never.self) {
            try await xcrun("xcodebuild", "-version").run(standardOutput: .nullDevice)
        }
    }

    @Test func version() {
        let command = xcrun.version
        let expected = ProcessCommand(path: "/usr/bin/xcrun", arguments: ["--version"])
        #expect(command == expected)
    }

    @Test func simulator() async throws {
        let simulator = try await xcrun.simctl
        #expect(simulator.path.hasSuffix("/usr/bin/simctl"))
    }

    @Test func find() async throws {
        let path = try await xcrun.find("xcodebuild")
        #expect(path.hasSuffix("/usr/bin/xcodebuild"))
    }
}

#endif // os(macOS)
