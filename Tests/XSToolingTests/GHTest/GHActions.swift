import Foundation

/// GitHub Actions
struct GHActions {
    let isEnabled: Bool

    func error(file: String, line: Int, message: String) {
        // ::error file={name},line={line},endLine={endLine},title={title}::{message}
        print("::error file=\(file),line=\(line)::\(message)")
    }

    func error(message: String) {
        print("::error::\(message)")
    }

    func group(_ name: String) {
        print("::group::\(name)")
    }

    func endGroup() {
        print("::endgroup::")
    }
}

extension GHActions {
    static let shared = GHActions(environment: ProcessInfo.processInfo.environment)

    init(environment: [String: String]) {
        isEnabled = environment["GITHUB_ACTIONS"] == "true"
    }
}
