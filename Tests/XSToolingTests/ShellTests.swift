import XCTest
import XSTooling

final class ShellTests: GHTestCase {
    private var shell: Shell!
    private var path: String!

    override func setUp() {
        super.setUp()
        path = "/bin/bash/\(name)"
        shell = Shell(path: path)
    }

    func testSh() async throws {
        shell = Shell.sh
        XCTAssertEqual(shell.path, "/bin/sh")

        let string = try await shell("echo 'hello world'").read().string
        XCTAssertEqual(string, "hello world")
    }

    func testBash() async throws {
        shell = Shell.bash
        XCTAssertEqual(shell.path, "/bin/bash")

        let string = try await shell("echo 'hello world'").read().string
        XCTAssertEqual(string, "hello world")
    }

    func testZsh() async throws {
        try XCTSkipIf(isLinux)
        
        shell = Shell.zsh
        XCTAssertEqual(shell.path, "/bin/zsh")

        let string = try await shell("echo 'hello world'").read().string
        XCTAssertEqual(string, "hello world")
    }

    func testVerbose() {
        XCTAssertEqual(shell.verbose, Shell(path: path, arguments: ["--verbose"]))
    }

    func testLogin() {
        XCTAssertEqual(shell.login, Shell(path: path, arguments: ["--login"]))
    }

    func testVersion() {
        XCTAssertEqual(shell.version, ProcessCommand(path: path, arguments: ["--version"]))
    }

    func testVerboseLoginVersion() {
        let command = shell.verbose.login.version

        let expected = ProcessCommand(
            path: path,
            arguments: ["--verbose", "--login", "--version"]
        )
        XCTAssertEqual(command, expected)

    }

    func testCallAsFunction() {
        let command = shell("xcrun xcodebuild -version")

        let expected = ProcessCommand(
            path: path,
            arguments: ["-c", "xcrun xcodebuild -version"]
        )
        XCTAssertEqual(command, expected)
    }
}
