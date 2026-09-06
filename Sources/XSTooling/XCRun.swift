/// Run or locate development tools and properties.
public struct XCRun: Equatable, Sendable {
    @TaskLocal
    public static var current = XCRun(path: "/usr/bin/xcrun")

    public var path: String

    /// Show the xcrun version.
    public var version: ProcessCommand {
        command(arguments: ["--version"])
    }

    /// A new simulator control.
    public var simctl: Simctl {
        get async throws {
            let path = try await find("simctl")
            return Simctl(path: path)
        }
    }

    /// Only find and return the tool path.
    ///
    /// - Parameter tool: The tool name.
    /// - Returns: The tool path.
    public func find(_ tool: String) async throws -> String {
        try await command(arguments: ["--find", tool]).read().string(strippingNewline: true)
    }

    public func callAsFunction(_ arguments: String...) -> ProcessCommand {
        command(arguments: arguments)
    }

    public func command(arguments: [String]) -> ProcessCommand {
        ProcessCommand(path: path, arguments: arguments)
    }
}
