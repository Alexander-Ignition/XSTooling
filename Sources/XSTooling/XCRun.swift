/// Run or locate development tools and properties.
public struct XCRun: Tool {
    public let path: String
    public let kernel: Kernel

    public init(
        path: String = "/usr/bin/xcrun",
        kernel: Kernel = .system
    ) {
        self.path = path
        self.kernel = kernel
    }

    /// Only find and return the tool path.
    ///
    /// - Parameter tool: The tool name.
    /// - Throws: `ProcessError`.
    /// - Returns: The tool path.
    public func find(_ tool: String) throws -> String {
        try execute("--find", tool).string
    }

    /// Find the simulator control.
    ///
    /// - Throws: `ProcessError`.
    /// - Returns: A new `Simctl`.
    public func simctl() throws -> Simctl {
        let path = try find("simctl")
        return Simctl(path: path, kernel: kernel)
    }
}
