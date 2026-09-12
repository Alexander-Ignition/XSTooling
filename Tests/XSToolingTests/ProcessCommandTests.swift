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

    @Test func `exit status check`() async {
        let command = bash("exit 2")
        let error = await #expect(throws: ProcessError.self) {
            try await command.run()
        }
        let expected = ProcessError(
            executableURL: command.executableURL,
            arguments: command.arguments,
            terminationStatus: 2,
            terminationReason: .exit
        )
        #expect(error == expected)
    }

    @Test func `run with error`() async throws {
        let error = await #expect(throws: CocoaError.self) {
            try await ProcessCommand(path: "/usr/local/bin/not/found").run()
        }
        #expect(error?.code == .fileNoSuchFile)
    }

    //    func testCancelRead() async throws {
    //        let task = Task(priority: .low) {
    //            try await ProcessCommand.bash("sleep 3").read()
    //        }
    //        task.cancel()
    //        do {
    //            let output = try await task.value
    //            XCTFail("Task not cancelled. Output: \(output.string)")
    //        } catch {
    //            XCTAssert(error is CancellationError, "Unexpected error: \(error)")
    //        }
    //    }
    //
    //    func testCancelWithRedirection() async throws {
    //        let task = Task(priority: .low) {
    //            try await ProcessCommand.bash("sleep 2").run()
    //        }
    //        task.cancel()
    //        do {
    //            _ = try await task.value
    //            XCTFail("Task not cancelled")
    //        } catch {
    //            XCTAssert(error is CancellationError, "Unexpected error: \(error)")
    //        }
    //    }

    @Test func cancel() async {
        let task = Task {
            try await bash("sleep 2 && echo 'end'").read().string
        }
        let task2 = Task {
            try await Task.sleep(for: .seconds(1))
            task.cancel()
        }
        defer {
            task2.cancel()
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
