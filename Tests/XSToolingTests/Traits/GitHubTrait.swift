import Foundation
import Testing

extension SuiteTrait where Self == GitHubTrait {
    static var gitHub: GitHubTrait {
        GitHubTrait()
    }
}

struct GitHubTrait: SuiteTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        guard GitHub.isActionsEnabled else {
            return try await function()
        }
        return try await _gitHubIssueHandlingTrait.provideScope(
            for: test,
            testCase: testCase,
            performing: function
        )
    }
}

private let _gitHubIssueHandlingTrait = IssueHandlingTrait.compactMapIssues { (issue: Issue) in
    GitHub.log(
        issue.workflowCommand,
        file: issue.sourceLocation?.filePath,
        line: issue.sourceLocation?.line,
        message: "\(issue)"
    )
    return issue
}

extension Issue {
    fileprivate var workflowCommand: GitHub.WorkflowCommand {
        switch severity {
        case .warning:
            GitHub.WorkflowCommand.warning
        case .error:
            GitHub.WorkflowCommand.error
        @unknown default:
            GitHub.WorkflowCommand.error
        }
    }
}

enum GitHub: Sendable {
    static let isActionsEnabled: Bool = ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true"

    /// [Workflow commands for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands)
    enum WorkflowCommand: String, Sendable {
        case warning
        case error
    }

    static func warning(file: String? = #filePath, line: Int? = #line, title: String? = nil, message: String) {
        log(.warning, file: file, line: line, message: message)
    }

    static func error(file: String? = #filePath, line: Int? = #line, title: String? = nil, message: String) {
        log(.error, file: file, line: line, message: message)
    }

    static func log(
        _ command: WorkflowCommand,
        file: String? = #filePath,
        line: Int? = #line,
        title: String? = nil,
        message: String,
    ) {
        func joinParameters() -> String {
            var parameters: [String] = []
            if let file {
                parameters.append("file=\(file)")
            }
            if let line {
                parameters.append("line=\(line)")
            }
            if let title {
                parameters.append("title=\(title)")
            }
            if parameters.isEmpty {
                return ""
            }
            return " " + parameters.joined(separator: ",")
        }
        print("::\(command)\(joinParameters())::\(message)")
    }
}
