import Foundation
import Testing
import XSTooling

@Suite(.gitHub)
struct ProcessOutputTests {

    @Test func string() {
        let output1 = ProcessOutput(data: Data("output\n".utf8))
        #expect(output1.string == "output")

        let output2 = ProcessOutput(data: Data("output".utf8))
        #expect(output2.string == "output")
    }

    @Test(arguments: [true, false])
    func string(strippingNewline: Bool) {
        let output = ProcessOutput(data: Data("done\n".utf8))
        let expected = strippingNewline ? "done" : "done\n"
        #expect(output.string(strippingNewline: strippingNewline) == expected)
    }

    @Test func decodeJson() throws {
        struct Status: Decodable {
            let code: Int
        }
        let output = ProcessOutput(data: Data(#"{ "code": 2} "#.utf8))
        #expect(try output.decode(Status.self).code == 2)
    }
}
