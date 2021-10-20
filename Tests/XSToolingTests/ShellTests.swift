import XCTest
import XSTooling

final class ShellTests: ToolTestCase {
    private var shell: Shell!

    override func setUp() {
        super.setUp()
        shell = Shell(path: path, kernel: kernel)
    }

    func testInitWithDefaults() {
        shell = Shell()
        XCTAssertEqual(shell.path, "/usr/bin/env")
        XCTAssertTrue(shell.kernel === Kernel.system)
    }

    func testCallAsFunction() {
        output = "swift/tests/1"
        XCTAssertEqual(try shell("pwd"), "swift/tests/1")
        XCTAssertEqual(commands, [["pwd"]])
    }

    func testWhich() {
        output = "/bin/ls"
        XCTAssertEqual(try shell.which("ls"), "/bin/ls")
        XCTAssertEqual(commands, [["which", "ls"]])
    }
}
