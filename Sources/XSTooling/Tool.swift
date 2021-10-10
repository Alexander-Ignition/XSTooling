public protocol Tool {
    /// The path to the location of the tool.
    var path: String { get }

    /// The kernel of command execution
    var kernel: Kernel { get }

    /// Execute command.
    ///
    /// - Returns: Command arguments.
    /// - Returns: Command output.
    /// - Throws: `ProcessError`.
    func execute(arguments: [String]) throws -> ProcessOutput
}

extension Tool {
    @discardableResult
    public func execute(_ arguments: String...) throws -> ProcessOutput {
        try execute(arguments: arguments)
    }

    public func execute(arguments: [String]) throws -> ProcessOutput {
        try kernel.execute(path: path, arguments: arguments)
    }
}
