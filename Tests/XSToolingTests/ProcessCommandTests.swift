import Foundation
import Testing
import XSTooling

@Suite(.gitHub, .serialized)
struct ProcessCommandTests {

    private func bash(_ command: String) -> ProcessCommand {
        ProcessCommand(path: "/bin/bash", arguments: ["-c", command])
    }

    @Test func defaults() {
        let command = ProcessCommand(path: "/bin/cat")

        #expect(command.executableURL == URL(fileURLWithPath: "/bin/cat"))
        #expect(command.currentDirectoryURL == nil)
        #expect(command.arguments == [])
        #expect(command.environment == nil)
    }

    @Test func `find executable in PATH`() {
        let command = ProcessCommand.find("ls")
        #expect(command == ProcessCommand(path: "/bin/ls"))
    }

    @Test func `not found executable in PATH`() {
        let command = ProcessCommand.find("ls-2")
        #expect(command == nil)
    }

    @Test func `read from stdout`() async throws {
        let command = bash("echo 'hello'; echo 'world!' >&2;")
        let output = try await command.read()

        #expect(output.data == Data("hello\n".utf8))
    }

    @Test func `read stdout and stderr combined`() async throws {
        let command = bash("echo 'hello'; echo 'world!' >&2;")
        let output = try await command.read(standardError: .standardOutput)

        #expect(output.string == "hello\nworld!")
    }

    @Test(.temporaryDirectory)
    func `redirect stdout and stderr to file`() async throws {
        let url = Test.temporaryDirectory!.appending(
            component: "logs.txt",
            directoryHint: .notDirectory
        )
        try #require(FileManager.default.createFile(atPath: url.path, contents: nil))
        let file = try FileHandle(forUpdating: url)

        let command = bash("echo 'Start'; echo 'Done!' >&2;")
        try await command.run(standardOutput: file, standardError: file)

        let string = try String(contentsOf: url, encoding: .utf8)
        #expect(string == "Start\nDone!\n")
    }

    @Test func `environment with custom variable`() async throws {
        var command = bash("echo $TEST_VALUE")
        command.environment = ["TEST_VALUE": "a"]

        let output = try await command.read()

        #expect(output.string == "a")
    }

    @Test func `environment from parent process`() async throws {
        precondition(setenv("TEST_VALUE", "b", 1) == 0)
        defer {
            precondition(unsetenv("TEST_VALUE") == 0)
        }
        let command = bash("echo $TEST_VALUE")
        let output = try await command.read()

        #expect(output.string == "b")
    }

    @Test func `run with error`() async {
        let error = await #expect(throws: CocoaError.self) {
            try await ProcessCommand(path: "/usr/local/bin/not/found").run()
        }
        #expect(error?.code == .fileNoSuchFile)
    }

    @Test func `exit status check`() async {
        let command = bash("exit 2")
        let error = ProcessError(
            executableURL: command.executableURL,
            arguments: command.arguments,
            terminationStatus: 2,
            terminationReason: .exit
        )
        await #expect(throws: error) {
            try await command.run()
        }
    }

    @Test func termination() async {
        let command = bash("sleep 2 && echo 'end'")
        let task = Task {
            try await command.read().string
        }
        let task2 = Task {
            try await Task.sleep(for: .seconds(1))
            task.cancel()
        }
        defer {
            task2.cancel()
        }
        let error = ProcessError(
            executableURL: command.executableURL,
            arguments: command.arguments,
            terminationStatus: 15,
            terminationReason: .uncaughtSignal
        )
        await #expect(throws: error) {
            try await task.value
        }
    }

    @Test func cancel() async throws {
        let task = Task(priority: .low) {
            await Task.yield()
            try await bash("sleep 3").run()
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
