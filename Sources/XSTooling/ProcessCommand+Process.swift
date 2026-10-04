#if !EnableSubprocess

import Foundation

extension ProcessCommand {

    func readProcess(standardError: FileHandle?) async throws -> ProcessOutput {
        let pipe = Pipe()
        let standardError: Any? = (standardError == FileHandle.standardOutput) ? pipe : standardError
        async let output = pipe.fileHandleForReading.stream().reduce(into: Data()) { $0.append($1) }
        try await runProcess(standardOutput: pipe, standardError: standardError)
        let data = await output
        return ProcessOutput(data: data)
    }

    func runProcess(standardOutput: Any?, standardError: Any?) async throws {
        let process = try makeProcess(standardOutput: standardOutput, standardError: standardError)
        try await process.perform()
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

extension Process {
    fileprivate func perform() async throws {
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

extension FileHandle {
    fileprivate func stream() -> AsyncStream<Data> {
        AsyncStream<Data> { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.readabilityHandler = nil // stop
            }
            self.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.isEmpty {
                    continuation.finish()
                } else {
                    continuation.yield(data)
                }
            }
        }
    }
}

#endif // !EnableSubprocess
