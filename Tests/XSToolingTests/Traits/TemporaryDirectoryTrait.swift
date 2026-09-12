import Foundation
import Testing

extension Trait where Self == TemporaryDirectoryTrait {
    static var temporaryDirectory: TemporaryDirectoryTrait {
        TemporaryDirectoryTrait()
    }
}

extension Test {
    @TaskLocal
    static var temporaryDirectory: URL?
}

struct TemporaryDirectoryTrait: TestTrait, SuiteTrait, TestScoping {
    var isRecursive: Bool { true }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        guard Test.temporaryDirectory == nil else {
            return try await function()
        }
        let fileManager = FileManager.default

        let url = fileManager.temporaryDirectory.appendingPathComponent(
            "\(test.sourceLocation.fileName)-\(test.sourceLocation.line)",
            isDirectory: true
        )
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        defer {
            try? fileManager.removeItem(at: url)
        }
        try await Test.$temporaryDirectory.withValue(url, operation: function)
    }
}
