import XCTest
import XSTooling

final class ProcessOutputTests: XCTestCase {

    private var output: ProcessOutput!

    override func setUp() {
        super.setUp()
        let command = ProcessCommand(path: "/usr/bin/ls")
        output = ProcessOutput(code: 0, reason: .exit, command: command)
    }

    func testChecked() {
        output.code = 0
        XCTAssertEqual(try output.check(), output)

        output.code = 1
        XCTAssertEqual(try output.check(code: 1), output)

        output.code = 1
        XCTAssertThrowsError(try output.check()) { error in
            XCTAssertNotNil(error as? ProcessOutputError)
        }
    }

    func testString() {
        output.standardOutput = Data("output\n".utf8)
        XCTAssertEqual(output.string, "output")

        output.standardOutput = Data("output".utf8)
        XCTAssertEqual(output.string, "output")
    }

    func testErrorDescription() {
        output.standardError = Data()
        XCTAssertNil(output.errorDescription)

        output.standardError = Data("error\n".utf8)
        XCTAssertEqual(output.errorDescription, "error")

        output.standardError = Data("error".utf8)
        XCTAssertEqual(output.errorDescription, "error")
    }

    func testDecode() {
        struct Status: Decodable {
            let code: Int
        }
        output.standardOutput = Data(#"{ "code": 2} "#.utf8)
        XCTAssertEqual(try output.decode(Status.self).code, 2)
    }
}
