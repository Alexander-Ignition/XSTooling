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
        shell.command.assert.equal(path: "/bin/sh")

        let string = try await shell("echo 'hello world'").read().string
        XCTAssertEqual(string, "hello world")
    }

    func testBash() async throws {
        shell = Shell.bash
        shell.command.assert.equal(path: "/bin/bash")

        let string = try await shell("echo 'hello world'").read().string
        XCTAssertEqual(string, "hello world")
    }

    func testZsh() async throws {
        try XCTSkipIf(isLinux)
        
        shell = Shell.zsh
        shell.command.assert.equal(path: "/bin/zsh")

        let string = try await shell("echo 'hello world'").read().string
        XCTAssertEqual(string, "hello world")
    }

    func testVerbose() {
        let command = shell.verbose.command

        command.assert.equal(path: path, arguments: "--verbose")
    }

    func testLogin() {
        let command = shell.login.command

        command.assert.equal(path: path, arguments: "--login")
    }

    func testVersion() {
        let command = shell.version

        command.assert.equal(path: path, arguments: "--version")
    }

    func testVerboseLoginVersion() {
        let command = shell.verbose.login.version

        command.assert.equal(path: path, arguments: "--verbose", "--login", "--version")
    }

    func testWhich() {
        let command = shell.which("ls")

        command.assert.equal(path: path, arguments: "-c", "which ls")
    }

    func testCallAsFunction() {
        let command = shell("xcrun xcodebuild -version")

        command.assert.equal(path: path, arguments: "-c", "xcrun xcodebuild -version")
    }
}
