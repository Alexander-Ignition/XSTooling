import Foundation

/// Redirecting the input output of an external command.
public struct ProcessRedirection: Equatable {
    enum Target: Equatable {
        /// A wrapper for a file descriptor.
        case file(FileHandle)

        /// A one-way communications channel between related processes.
        case pipe(Pipe)
    }

    /// The standard output for the receiver.
    var standardOutput: Target?

    /// The standard error for the receiver.
    var standardError: Target?

    /// A new empty redirection.
    public init() {}

    // MARK: - Output

    public static func output(_ file: FileHandle) -> ProcessRedirection {
        ProcessRedirection().output(file)
    }

    public static func output(_ pipe: Pipe) -> ProcessRedirection {
        ProcessRedirection().output(pipe)
    }

    public func output(_ file: FileHandle) -> ProcessRedirection {
        copy(standardOutput: .file(file))
    }

    public func output(_ pipe: Pipe) -> ProcessRedirection {
        copy(standardOutput: .pipe(pipe))
    }

    // MARK: - Error

    public static func error(_ file: FileHandle) -> ProcessRedirection {
        ProcessRedirection().error(file)
    }

    public static func error(_ pipe: Pipe) -> ProcessRedirection {
        ProcessRedirection().error(pipe)
    }

    public func error(_ file: FileHandle) -> ProcessRedirection {
        copy(standardError: .file(file))
    }

    public func error(_ pipe: Pipe) -> ProcessRedirection {
        copy(standardError: .pipe(pipe))
    }

    // MARK: - Copy

    private func copy(standardOutput: Target?) -> ProcessRedirection {
        var redirection = self
        redirection.standardOutput = standardOutput
        return redirection
    }

    private func copy(standardError: Target?) -> ProcessRedirection {
        var redirection = self
        redirection.standardError = standardError
        return redirection
    }
}

// MARK: - Target properties

extension ProcessRedirection.Target {
    var object: Any {
        switch self {
        case .file(let fileHandle):
            return fileHandle
        case .pipe(let pipe):
            return pipe
        }
    }
}

