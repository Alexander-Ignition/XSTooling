import XCTest
import XSTooling

class ToolTestCase: XCTestCase {
    /// Tool execution kernel.
    private(set) var kernel: Kernel!

    /// All executed commands.
    private(set) var commands: [String]!

    /// Unique tool path for each test.
    var path: String { name }

    /// Tool execution output.
    var output: ProcessOutput!

    override func setUp() {
        super.setUp()
        commands = []
        output = ""
        kernel = Kernel { [unowned self] path, arguments in
            XCTAssertEqual(path, self.path)
            let command = arguments.joined(separator: " ")
            self.commands.append(command)
            return self.output
        }
    }
}
