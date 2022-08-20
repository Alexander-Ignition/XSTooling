/// Run or locate development tools and properties.
public struct XCRun: ExternalTool, Equatable {
    public var command: Command

    public init(path: String = "/usr/bin/xcrun") {
        self.command = Command(path: path)
    }

    public init(command: Command) {
        self.command = command
    }

    /// Show the xcrun version.
    public var version: Command {
        command.argument("--version")
    }

    /// Only find and return the tool path.
    ///
    /// - Parameter tool: The tool name.
    /// - Returns: The tool path.
    public func find(_ tool: String) -> Command {
        command.arguments("--find", tool)
    }

    /// A new simulator control.
    public var simctl: Simctl {
        Simctl(command: command.argument("simctl"))
    }
}
