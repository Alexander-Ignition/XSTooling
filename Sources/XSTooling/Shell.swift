import Foundation

public struct Shell: ExternalTool, Equatable {
    /// Basic command.
    ///
    /// Contains common parameters for all commands in the tool.
    public var command: Command

    /// A new shell.
    ///
    /// - Parameter path: executable file location.
    public init(path: String) {
        self.command = Command(path: path)
    }

    public func callAsFunction(_ string: String) -> Command {
        command(string: string)
    }

    public func command(string: String) -> Command {
        command.arguments("-c", string)
    }
}

// MARK: - Shells

extension Shell {
    /// The preferred shell or bash.
    public static var `default`: Shell { preferred ?? bash }

    /// POSIX-compliant command interpreter.
    public static let sh = Shell(path: "/bin/sh")

    /// GNU Bourne-Again SHell.
    public static let bash = Shell(path: "/bin/bash")

    /// The Z shell.
    public static let zsh = Shell(path: "/bin/zsh")

    /// The preferred shell specified in the environment.
    public static var preferred: Shell? {
        ProcessInfo.processInfo.environment["SHELL"].map { Shell(path: $0) }
    }
}

// MARK: - Options

extension Shell {
    public var verbose: Shell { option("--verbose") }

    public var login: Shell { option("--login") }

    func option(_ value: String) -> Shell {
        var shell = self
        shell.command.arguments.append(value)
        return shell
    }
}

// MARK: - Commands

extension Shell {
    /// Show version information for this instance of bash on the standard output and exit successfully.
    public var version: Command {
        command.argument("--version")
    }

    /// Locate a program file in the user's path.
    public func which(_ name: String) -> Command {
        command(string: "which \(name)")
    }
}
