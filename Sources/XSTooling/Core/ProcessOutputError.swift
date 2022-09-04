import Foundation

/// Process execution error.
public struct ProcessOutputError: Error, Equatable {
    /// Output of the process that ended with an error.
    public let output: ProcessOutput

    public init(output: ProcessOutput) {
        self.output = output
    }
}

extension ProcessOutputError: LocalizedError {
    /// Error description from standard error stream.
    public var errorDescription: String? {
        output.errorDescription
    }
}

extension ProcessOutputError: CustomNSError {
    public var errorCode: Int { Int(output.code) }

    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = errorDescription
        return userInfo
    }
}
