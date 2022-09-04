import Foundation

/// Output of the process execution.
public struct ProcessOutput: Hashable {
    /// Constants that specify the termination reason values that the system returns.
    public typealias TerminationReason = Process.TerminationReason

    /// The exit status the receiver’s executable returns.
    public var code: Int32

    /// The reason the system terminated the task.
    public var reason: TerminationReason

    /// Failed executable command.
    public var command: ProcessCommand

    /// Bytes from standard output stream.
    public var standardOutput: Data

    /// Bytes from standard error stream.
    public var standardError: Data

    public init(
        code: Int32,
        reason: TerminationReason,
        command: ProcessCommand,
        standardOutput: Data = Data(),
        standardError: Data = Data()
    ) {
        self.code = code
        self.reason = reason
        self.command = command
        self.standardOutput = standardOutput
        self.standardError = standardError
    }

    // MARK: - Check

    /// Check the success status of the exit code.
    ///
    /// - Parameter code: success exit code. Default 0.
    /// - Returns: same output.
    /// - Throws: `ProcessOutputError`.
    @discardableResult
    public func check(code: Int32 = 0) throws -> ProcessOutput {
        if self.code != code {
            throw ProcessOutputError(output: self)
        }
        return self
    }

    // MARK: - String

    /// UTF8 string from standard output stream.
    public var string: String {
        standardOutput.string(strippingNewline: true)
    }

    /// Error description from standard error stream.
    public var errorDescription: String? {
        guard !standardError.isEmpty else {
            return nil
        }
        return standardError.string(strippingNewline: true)
    }

    // MARK: - JSON

    /// Default JSON decoder.
    private static let decoder = JSONDecoder()

    public func decode<T>(
        _ type: T.Type,
        using decoder: JSONDecoder? = nil
    ) throws -> T where T: Decodable {

        try (decoder ?? Self.decoder).decode(type, from: standardOutput)
    }
}

extension Data {
    private static let newLine = UInt8(ascii: "\n")

    fileprivate func string(strippingNewline: Bool) -> String {
        var buffer = self
        if strippingNewline, buffer.last == Self.newLine { // TODO: \r\n or \n
            buffer = buffer.dropLast()
        }
        return String(decoding: buffer, as: UTF8.self)
    }
}
