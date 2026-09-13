import Foundation

public struct ProcessCommand: Hashable, Sendable {
    public static func find(_ name: String) -> ProcessCommand? {
        ProcessInfo
            .processInfo
            .environment["PATH"]?
            .split(separator: ":")
            .lazy
            .map { URL(fileURLWithPath: String($0), isDirectory: true).appendingPathComponent(name) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
            .map { ProcessCommand(executableURL: $0) }
    }

    /// The receiver’s executable.
    public var executableURL: URL

    /// The command arguments that the system uses to launch the executable.
    public var arguments: [String]

    /// The environment for the executable.
    public var environment: [String: String]?

    /// The current directory for the receiver.
    public var currentDirectoryURL: URL?

    public init(
        executableURL: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
    ) {
        self.executableURL = executableURL
        self.environment = environment
        self.arguments = arguments
        self.currentDirectoryURL = currentDirectoryURL
    }

    public init(
        path: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectoryPath: String? = nil,
    ) {
        self.init(
            executableURL: URL(fileURLWithPath: path, isDirectory: false),
            arguments: arguments,
            environment: environment,
            currentDirectoryURL: currentDirectoryPath.map {
                URL(fileURLWithPath: $0, isDirectory: true)
            })
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

    public func read(standardError: FileHandle? = nil) async throws -> ProcessOutput {
        let pipe = Pipe()
        let standardError: Any? = (standardError == FileHandle.standardOutput) ? pipe : standardError
        async let output = pipe.fileHandleForReading.stream().reduce(into: Data()) { $0.append($1) }
        try await runProcess(standardOutput: pipe, standardError: standardError)
        let data = await output
        return ProcessOutput(data: data)
    }

    public func run(standardOutput: FileHandle? = nil, standardError: FileHandle? = nil) async throws {
        try await runProcess(standardOutput: standardOutput, standardError: standardError)
    }

    // MARK: - Private

    private func runProcess(standardOutput: Any?, standardError: Any?) async throws {
        let process = try makeProcess(standardOutput: standardOutput, standardError: standardError)
        try await process.execute()
        if process.terminationStatus != 0 {
            throw ProcessError(
                executableURL: executableURL,
                arguments: arguments,
                terminationStatus: process.terminationStatus,
                terminationReason: process.terminationReason
            )
        }
    }

    private func makeProcess(standardOutput: Any?, standardError: Any?) throws -> Process {
        let process = Process()
        process.executableURL = executableURL
        process.currentDirectoryURL = currentDirectoryURL
        process.arguments = arguments
        if let environment {
            process.environment = environment
        }
        if let standardOutput {
            process.standardOutput = standardOutput
        }
        if let standardError {
            process.standardError = standardError
        }
        return process
    }
}

public struct ProcessOutput: Sendable {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }

    public var string: String {
        string(strippingNewline: true)
    }

    public func string(strippingNewline: Bool) -> String {
        var string = String(decoding: data, as: UTF8.self)
        if strippingNewline, string.last?.isNewline == true {
            string.removeLast()
        }
        return string
    }

    @usableFromInline static let decoder = JSONDecoder()

    @inlinable public func decode<T>(
        _ type: T.Type,
        using decoder: JSONDecoder? = nil
    ) throws -> T where T: Decodable {
        try (decoder ?? Self.decoder).decode(type, from: data)
    }
}

public struct ProcessError: Error, Equatable {
    public let executableURL: URL
    public let arguments: [String]
    public let terminationStatus: Int32
    public let terminationReason: Process.TerminationReason

    public init(
        executableURL: URL,
        arguments: [String],
        terminationStatus: Int32,
        terminationReason: Process.TerminationReason
    ) {
        self.executableURL = executableURL
        self.arguments = arguments
        self.terminationStatus = terminationStatus
        self.terminationReason = terminationReason
    }
}

// MARK: - Process

extension Process {
    fileprivate func execute() async throws {
        try Task.checkCancellation()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.terminationHandler = { process in
                    process.terminationHandler = nil
                    continuation.resume()
                }
                do {
                    try self.run()
                } catch {
                    self.terminationHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: { // can be canceled without starting
            if self.isRunning {
                self.terminate() // crash if not running
            }
        }
    }
}

// MARK: - FileHandle + AsyncStream

extension FileHandle {
    fileprivate func stream() -> AsyncStream<Data> {
        AsyncStream<Data> { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.readabilityHandler = nil // stop
            }
            self.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.isEmpty {
                    fileHandle.readabilityHandler = nil // stop
                    continuation.finish()
                } else {
                    continuation.yield(data)
                }
            }
        }
    }
}
