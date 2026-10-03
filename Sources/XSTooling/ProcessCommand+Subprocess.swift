#if EnableSubprocess
public import Subprocess

import Foundation

#if canImport(System)
import System
#else
import SystemPackage
#endif

extension ProcessCommand {

    public var subprocessConfiguration: Subprocess::Configuration {
        Subprocess::Configuration(
            executable: .path(FilePath(self.executableURL.path)),
            arguments: Arguments(self.arguments),
            environment: self.subprocessEnvironment,
            workingDirectory: self.currentDirectoryURL.map { FilePath($0.path) },
        )
    }

    private var subprocessEnvironment: Subprocess::Environment {
        guard let environment else {
            return .inherit
        }
        let dict = environment.reduce(
            into: [Environment.Key: String](minimumCapacity: environment.count),
            { dict, element in
                if let key = Environment.Key(rawValue: element.key) {
                    dict[key] = element.value
                }
            })
        return .custom(dict)
    }

    func readSubprocess(standardError: FileHandle?, limit: Int) async throws -> ProcessOutput {
        let values: (terminationStatus: TerminationStatus, standardOutput: Data)
        if standardError == FileHandle.standardOutput {
            let result = try await Subprocess::run(
                self.subprocessConfiguration,
                output: .data(limit: limit),
                error: .combinedWithOutput,
            )
            values = (result.terminationStatus, result.standardOutput)
        } else {
            let result = try await Subprocess::run(
                self.subprocessConfiguration,
                output: .data(limit: limit),
                error: standardError?.fileDescriptorOutput ?? .currentStandardError,
            )
            values = (result.terminationStatus, result.standardOutput)
        }
        try check(terminationStatus: values.terminationStatus)
        return ProcessOutput(data: values.standardOutput)
    }

    func runSubprocess(
        standardOutput: FileHandle?,
        standardError: FileHandle?,
    ) async throws {
        let result = try await Subprocess::run(
            self.subprocessConfiguration,
            output: standardOutput?.fileDescriptorOutput ?? .currentStandardOutput,
            error: standardError?.fileDescriptorOutput ?? .currentStandardError,
        )
        try check(terminationStatus: result.terminationStatus)
    }

    private func check(terminationStatus: TerminationStatus) throws {
        if terminationStatus.isSuccess {
            return
        }
        throw ProcessError(
            executableURL: executableURL,
            arguments: arguments,
            terminationStatus: terminationStatus.terminationCode,
            terminationReason: terminationStatus.terminationReason,
        )
    }
}

extension TerminationStatus {

    fileprivate var terminationCode: Code {
        switch self {
        case .exited(let code), .signaled(let code): code
        }
    }

    fileprivate var terminationReason: Process.TerminationReason {
        switch self {
        case .exited: .exit
        case .signaled: .uncaughtSignal
        }
    }
}

extension FileHandle {
    fileprivate var fileDescriptorOutput: FileDescriptorOutput {
        .fileDescriptor(
            FileDescriptor(rawValue: self.fileDescriptor),
            closeAfterSpawningProcess: false
        )
    }
}

#endif // EnableSubprocess
