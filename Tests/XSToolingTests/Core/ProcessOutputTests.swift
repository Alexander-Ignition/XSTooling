import XCTest
import XSTooling

final class ProcessOutputTests: GHTestCase {

    func testString() {
        let output1 = ProcessOutput(data: Data("output\n".utf8))
        XCTAssertEqual(output1.string, "output")

        let output2 = ProcessOutput(data: Data("output\n".utf8))
        XCTAssertEqual(output2.string, "output")
    }

    func testDecode() {
        struct Status: Decodable {
            let code: Int
        }
        let output = ProcessOutput(data: Data(#"{ "code": 2} "#.utf8))
        XCTAssertEqual(try output.decode(Status.self).code, 2)
    }
}
