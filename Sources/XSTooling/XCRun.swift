/// Run or locate development tools and properties.
public struct XCRun: Equatable, Sendable {
    public var command: ProcessCommand

    public init(path: String = "/usr/bin/xcrun") {
        self.command = ProcessCommand(path: path)
    }

    public init(command: ProcessCommand) {
        self.command = command
    }

    /// Show the xcrun version.
    public var version: ProcessCommand {
        command.appending(argument: "--version")
    }

    /// Only find and return the tool path.
    ///
    /// - Parameter tool: The tool name.
    /// - Returns: The tool path.
    public func find(_ tool: String) -> ProcessCommand {
        command.appending(arguments: "--find", tool)
    }

    /// A new simulator control.
    public var simctl: Simctl {
        Simctl(command: command.appending(argument: "simctl"))
    }
}
