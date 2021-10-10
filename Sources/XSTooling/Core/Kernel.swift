import Foundation

/// The kernel of command execution.
public final class Kernel {
    /// System execution of commands.
    public static let system = Kernel(execution: _execute(path:arguments:))

    public typealias Execution = (_ path: String, _ arguments: [String]) throws -> ProcessOutput

    private let _execution: Execution

    public init(execution: @escaping Execution) {
        _execution = execution
    }

    public func execute(path: String, arguments: [String]) throws -> ProcessOutput {
        try _execution(path, arguments)
    }

    public var printed: Kernel {
        Kernel { path, arguments in
            print("execute:", path, arguments.joined(separator: " "))
            let output = try self.execute(path: path, arguments: arguments)
            print("output :", output)
            return output
        }
    }
}

private func _execute(path: String, arguments: [String]) throws -> ProcessOutput {
    let process = Process()
    process.launchPath = path
    process.arguments = arguments

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()

    let output = try stdout.readToEnd()
    let error = try stderr.readToEnd()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw ProcessError(
            status: process.terminationStatus,
            reason: process.terminationReason,
            data: error)
    }
    return ProcessOutput(data: output)
}

extension Pipe {
    func readToEnd() throws -> Data {
        if #available(macOS 10.15.4, *) {
            return try fileHandleForReading.readToEnd() ?? Data()
        } else {
            return fileHandleForReading.readDataToEndOfFile()
        }
    }
}
