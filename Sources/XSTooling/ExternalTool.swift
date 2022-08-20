/// Wrapper over an external CLI application.
public protocol ExternalTool {
    typealias Command = ProcessCommand

    /// Basic command.
    ///
    /// Contains common parameters for all commands in the tool.
    var command: Command { get }
}
