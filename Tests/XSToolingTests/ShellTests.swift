import XCTest
import XSTooling

final class ShellTests: ToolTestCase {
    private var shell: Shell!

    override func setUp() {
        super.setUp()
        shell = Shell(path: path, arguments: ["-v"], kernel: kernel)
    }

    func testSh() {
        shell = Shell.sh
        XCTAssertEqual(shell.path, "/bin/sh")
        XCTAssertEqual(shell.arguments, ["-c"])
        XCTAssertTrue(shell.kernel === Kernel.system)
        XCTAssertNoThrow(try shell("ls -al"))
    }

    func testBash() {
        shell = Shell.bash
        XCTAssertEqual(shell.path, "/bin/bash")
        XCTAssertEqual(shell.arguments, ["-c"])
        XCTAssertTrue(shell.kernel === Kernel.system)
        XCTAssertNoThrow(try shell("ls -al"))
    }

    func testExecute() {
        output = "swift/tests/1"
        XCTAssertEqual(try shell.execute("ls", "-al"), "swift/tests/1")
        XCTAssertEqual(commands, [["-v", "ls -al"]])
    }

    func testCallAsFunction() {
        output = "swift/tests/1"
        XCTAssertEqual(try shell("pwd"), "swift/tests/1")
        XCTAssertEqual(commands, [["-v", "pwd"]])
    }

    func testWhich() {
        output = "/bin/ls"
        XCTAssertEqual(try shell.which("ls"), "/bin/ls")
        XCTAssertEqual(commands, [["-v", "which ls"]])
    }
}
