import XCTest
import XSTooling

extension ProcessCommand {
    static func bash(_ command: String, successCode: Int32? = 0) -> ProcessCommand {
        ProcessCommand(path: "/bin/bash", arguments: ["-c", command])
    }
}

final class ProcessCommandTests: GHTestCase {

    func testInitWithDefaults() {
        let command = ProcessCommand(path: "/bin/cat")

        XCTAssertEqual(command.executableURL, URL(fileURLWithPath: "/bin/cat"))
        XCTAssertEqual(command.arguments, [])
        XCTAssertNil(command.environment)
        XCTAssertNil(command.currentDirectoryURL)
    }

    func testRead() async throws {
        let command = ProcessCommand.bash("echo 'hello'")

        let output = try await command.read()

        XCTAssertEqual(output.data, Data("hello\n".utf8))
    }

    func testReadStandardError() async throws {
        let command = ProcessCommand.bash("echo 'hello'; echo 'world!' >&2;")

        let output = try await command.read(standardError: .standardOutput)

        XCTAssertEqual(output.string, "hello\nworld!")
    }

    func testRunWithRedirection() async throws {
        let command = ProcessCommand.bash("echo 'test'")

        try await command.run(standardOutput: .standardOutput, standardError: .standardOutput)
    }

    func testEnvironment() async throws {
        var command = ProcessCommand.bash("echo $XSTOOLING_TEST_VALUE")
        command.environment = ["XSTOOLING_TEST_VALUE": "a"]

        let output = try await command.read()

        XCTAssertEqual(output.string, "a")
    }

    func testEnvironmentFromParentProcess() async throws {
        var command = ProcessCommand.bash("echo $XSTOOLING_TEST_VALUE")
        command.environment = nil

        precondition(setenv("XSTOOLING_TEST_VALUE", "b", 1) == 0)
        addTeardownBlock {
            precondition(unsetenv("XSTOOLING_TEST_VALUE") == 0)
        }
        let output = try await command.read()

        XCTAssertEqual(output.string, "b")
    }

    func testSuccessCodeCheck() async {
        let command = ProcessCommand.bash("exit 1")
        let expectedError = ProcessError(
            executableURL: command.executableURL,
            arguments: command.arguments,
            terminationStatus: 1,
            terminationReason: .exit
        )
        do {
            try await command.run()
            XCTFail("The exit code has not been checked")
        } catch let error as ProcessError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRunWithError() async throws {
        let command = ProcessCommand(path: "/usr/local/bin/not/found")
        do {
            try await command.run()
            XCTFail("The exit code has not been checked")
        } catch {
            XCTAssertFalse(error is ProcessError)
        }
    }

    func testCancelRead() async throws {
        let task = Task(priority: .low) {
            try await ProcessCommand.bash("sleep 3").read()
        }
        task.cancel()
        do {
            let output = try await task.value
            XCTFail("Task not cancelled. Output: \(output.string)")
        } catch {
            XCTAssert(error is CancellationError, "Unexpected error: \(error)")
        }
    }

    func testCancelWithRedirection() async throws {
        let task = Task(priority: .low) {
            try await ProcessCommand.bash("sleep 2").run()
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Task not cancelled")
        } catch {
            XCTAssert(error is CancellationError, "Unexpected error: \(error)")
        }
    }

    func testTerminate() async throws {
        try XCTSkipIf(isLinux)

        let task = Task {
            try await ProcessCommand.bash("sleep 2 && echo 'end'", successCode: nil).run()
        }
        Task {
            try await Task.sleep(nanoseconds: 1_000_000)
            task.cancel()
        }
        do {
            _ = try await task.value
        } catch {
            XCTAssert(error is CancellationError, "Unexpected error: \(error)")
        }
    }
}
