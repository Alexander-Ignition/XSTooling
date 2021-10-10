public struct Shell: Tool {
    public let path: String
    public let kernel: Kernel

    public init(
        path: String = "/usr/bin/env",
        kernel: Kernel = .system
    ) {
        self.path = path
        self.kernel = kernel
    }

    @discardableResult
    public func callAsFunction(_ arguments: String...) throws -> ProcessOutput {
        try execute(arguments: arguments)
    }

    public func which(_ tool: String) throws -> String {
        try execute("which", tool).string
    }
}
