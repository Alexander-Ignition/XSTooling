public struct Shell: Tool {
    /// POSIX-compliant command interpreter.
    public static let sh = Shell(path: "/bin/sh", arguments: ["-c"])

    /// GNU Bourne-Again SHell.
    public static let bash = Shell(path: "/bin/bash", arguments: ["-c"])

    public var path: String
    public var arguments: [String]
    public var kernel: Kernel

    public init(path: String, arguments: [String], kernel: Kernel = .system) {
        self.path = path
        self.arguments = arguments
        self.kernel = kernel
    }

    @discardableResult
    public func callAsFunction(_ arguments: String...) throws -> ProcessOutput {
        try execute(arguments: arguments)
    }

    public func which(_ tool: String) throws -> String {
        try execute("which", tool).string
    }

    public func execute(arguments: [String]) throws -> ProcessOutput {
        let script = arguments.joined(separator: " ")
        return try kernel.execute(path: path, arguments: self.arguments + [script])
    }
}
