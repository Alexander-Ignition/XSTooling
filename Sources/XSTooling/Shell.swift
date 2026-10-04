import Foundation

public struct Shell: Equatable, Sendable {
    @TaskLocal
    public static var current: Shell = {
        let path = ProcessInfo.processInfo.environment["SHELL"]
        return path.map { Shell(path: $0) } ?? bash
    }()

    /// POSIX-compliant command interpreter.
    public static var sh: Shell {
        Shell(path: "/bin/sh")
    }

    /// GNU Bourne-Again SHell.
    public static var bash: Shell {
        Shell(path: "/bin/bash")
    }

    /// The Z shell.
    public static var zsh: Shell {
        Shell(path: "/bin/zsh")
    }

    public var path: String
    public var arguments: [String]

    public init(path: String, arguments: [String] = []) {
        self.path = path
        self.arguments = arguments
    }

    /// Show version information for this instance of bash on the standard output and exit successfully.
    public var version: ProcessCommand {
        ProcessCommand(path: path, arguments: arguments).appending(argument: "--version")
    }

    public func callAsFunction(_ string: String) -> ProcessCommand {
        command(string: string)
    }

    public func command(string: String) -> ProcessCommand {
        var arguments = self.arguments
        arguments.append("-c")
        arguments.append(string)
        return ProcessCommand(path: path, arguments: arguments)
    }
}
