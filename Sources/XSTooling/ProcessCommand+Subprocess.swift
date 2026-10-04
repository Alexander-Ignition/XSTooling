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
        let config = self.subprocessConfiguration
        let output = DataOutput.data(limit: limit)
        lazy var error = standardError?.fileDescriptorOutput ?? .currentStandardError

        let (terminationStatus, standardOutput) =
            switch standardError {
            case .standardOutput:
                try await Subprocess::run(config, output: output, error: .combinedWithOutput).dataOutput
            case .nullDevice:
                try await Subprocess::run(config, output: output, error: .discarded).dataOutput
            default:
                try await Subprocess::run(config, output: output, error: error).dataOutput
            }
        try check(terminationStatus: terminationStatus)
        return ProcessOutput(data: standardOutput)
    }

    func runSubprocess(
        standardOutput: FileHandle?,
        standardError: FileHandle?,
    ) async throws {

        let config = self.subprocessConfiguration
        lazy var output = standardOutput?.fileDescriptorOutput ?? .currentStandardOutput
        lazy var error = standardError?.fileDescriptorOutput ?? .currentStandardError

        let status =
            switch (standardOutput, standardError) {
            case (.nullDevice, .nullDevice):
                try await Subprocess::run(config, output: .discarded, error: .discarded).terminationStatus
            case (_, .nullDevice):
                try await Subprocess::run(config, output: output, error: .discarded).terminationStatus
            case (.nullDevice, _):
                try await Subprocess::run(config, output: .discarded, error: error).terminationStatus
            default:
                try await Subprocess::run(config, output: output, error: error).terminationStatus
            }
        try check(terminationStatus: status)
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

extension ExecutionResult where Output == DataOutput {
    fileprivate var dataOutput: (TerminationStatus, Data) {
        (terminationStatus, standardOutput)
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
