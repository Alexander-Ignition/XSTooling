import Foundation

public struct ProcessCommand: Hashable, Sendable {
    public static func find(_ name: String) -> ProcessCommand? {
        guard let string = ProcessInfo.processInfo.environment["PATH"] else {
            return nil
        }
        let paths = string.split(separator: ":")
        for substring in paths {
            let directory = URL(fileURLWithPath: String(substring), isDirectory: true)
            let url = directory.appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return ProcessCommand(executableURL: url)
            }
        }
        return nil
    }

    /// The receiver’s executable.
    public var executableURL: URL
    
    /// The command arguments that the system uses to launch the executable.
    public var arguments: [String]

    /// The environment for the executable.
    public var environment: [String: String]?

    /// The current directory for the receiver.
    public var currentDirectoryURL: URL?

    /// Successful exit code. Default 0.
    ///
    /// Set `nil` if you don't want to check the exit code.
    public var successCode: Int32?

    public init(
        executableURL: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
        successCode: Int32? = 0
    ) {
        self.executableURL = executableURL
        self.environment = environment
        self.arguments = arguments
        self.currentDirectoryURL = currentDirectoryURL
        self.successCode = successCode
    }

    public init(
        path: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryPath: String? = nil,
        successCode: Int32? = 0
    ) {
        self.init(
            executableURL: URL(fileURLWithPath: path, isDirectory: false),
            arguments: arguments,
            environment: environment,
            currentDirectoryURL: currentDirectoryPath.map {
                URL(fileURLWithPath: $0, isDirectory: true)
            },
            successCode: successCode)
    }

    // MARK: - Arguments

    public func appending(argument: String) -> ProcessCommand {
        var copy = self
        copy.arguments.append(argument)
        return copy
    }

    public func appending(arguments: String...) -> ProcessCommand {
        appending(arguments: arguments)
    }

    public func appending(arguments: [String]) -> ProcessCommand {
        var copy = self
        copy.arguments.append(contentsOf: arguments)
        return copy
    }

    // MARK: - Running

    /// Run and read from standard output and standard error streams.
    ///
    /// - Throws: `CancellationError` if cancelled before running.
    /// - Throws: `ProcessOutputError` if the exit code is not equal to `successCode`.
    /// - Returns: The command output with collected bytes from standard output and standard error streams.
    public func read() async throws -> ProcessOutput {
        try await _check(_read())
    }

    /// Runs the command with the current environment.
    ///
    /// By default, during command execution, reads from stdout and stderr occur.
    /// This behavior can be changed by passing `redirection`.
    ///
    /// - Throws: `CancellationError` if cancelled before running.
    /// - Throws: `ProcessOutputError` if the exit code is not equal to `successCode`.
    /// - Parameter redirection: A subprocess input / output. Default `nil`.
    /// - Returns: The command output.
    @discardableResult
    public func run(_ redirection: ProcessRedirection? = nil) async throws -> ProcessOutput {
        try await _check(_run(redirection))
    }

    // MARK: - Private

    private func _check(_ output: ProcessOutput) throws -> ProcessOutput {
        if let success = successCode {
            try output.check(code: success)
        }
        return output
    }

    private func _read() async throws -> ProcessOutput {
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        let outputReader = outputPipe.fileHandleForReading.reader()
        let errorReader = errorPipe.fileHandleForReading.reader()

        defer {
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
        }

        var result = try await _run(.output(outputPipe).error(errorPipe))

        result.standardOutput = outputReader.data
        result.standardError = errorReader.data

        return result
    }

    private func _run(_ redirection: ProcessRedirection?) async throws -> ProcessOutput {
        let process = _process(redirection: redirection)

        try await process.async.run()

        let code = process.terminationStatus
        let reason = process.terminationReason
        return ProcessOutput(code: code, reason: reason, command: self)
    }

    private func _process(redirection: ProcessRedirection?) -> Process {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        if let environment = environment {
            process.environment = environment
        }
        process.currentDirectoryURL = currentDirectoryURL
        if let standardOutput = redirection?.standardOutput?.object {
            process.standardOutput = standardOutput
        }
        if let standardError = redirection?.standardError?.object {
            process.standardError = standardError
        }
        return process
    }
}
