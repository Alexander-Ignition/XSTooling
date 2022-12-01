import XCTest
import XSTooling

extension ProcessCommand {
    static func bash(_ command: String, successCode: Int32? = 0) -> ProcessCommand {
        ProcessCommand(path: "/bin/bash", arguments: ["-c", command], successCode: successCode)
    }
}

final class ProcessCommandTests: XCTestCase {

    func testInitWithDefaults() {
        let command = ProcessCommand(path: "/bin/cat")

        XCTAssertEqual(command.executableURL, URL(fileURLWithPath: "/bin/cat"))
        XCTAssertEqual(command.arguments, [])
        XCTAssertNil(command.environment)
        XCTAssertNil(command.currentDirectoryURL)
        XCTAssertEqual(command.successCode, 0)
    }

    func testRead() async throws {
        let command = ProcessCommand.bash("echo 'hello'")

        let output = try await command.read()

        XCTAssertEqual(output.code, 0)
        XCTAssertEqual(output.reason, .exit)
        XCTAssertEqual(output.command, command)
        XCTAssertEqual(output.standardOutput, Data("hello\n".utf8))
        XCTAssertEqual(output.standardError, Data())
    }

    func testRunWithRedirection() async throws {
        let command = ProcessCommand.bash("echo 'test'")

        let output = try await command.run(.output(.standardOutput).error(.standardOutput))

        XCTAssertEqual(output.code, 0)
        XCTAssertEqual(output.reason, .exit)
        XCTAssertEqual(output.command, command)
        XCTAssertEqual(output.standardOutput, Data())
        XCTAssertEqual(output.standardError, Data())
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
        let output = ProcessOutput(code: 1, reason: .exit, command: command)
        let expectedError = ProcessOutputError(output: output)
        do {
            let output = try await command.run()
            XCTFail("The exit code has not been checked: \(output)")
        } catch let error as ProcessOutputError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReadWithError() async throws {
        let command = ProcessCommand(path: "/usr/local/bin/not/found")
        do {
            let output = try await command.run()
            XCTFail("\(output)")
        } catch {
            XCTAssertFalse(error is ProcessOutputError)
        }
    }

    func testCancelRead() async throws {
        let task = Task(priority: .low) {
            try await ProcessCommand.bash("sleep 3").read()
        }
        task.cancel()
        do {
            let result = try await task.value
            XCTFail("Task not cancelled. Exit code: \(result.code)")
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
            let result = try await task.value
            XCTFail("Task not cancelled. Exit code: \(result.code)")
        } catch {
            XCTAssert(error is CancellationError, "Unexpected error: \(error)")
        }
    }

    func testTerminate() async throws {
        let task = Task.detached {
            try await ProcessCommand.bash("sleep 2 && echo 'end'", successCode: nil).run()
        }
        print("cancel 1")
        try await Task.sleep(nanoseconds: 1_000_000)
        print("cancel 2")
        task.cancel()
        print("cancel 3")
        let result = try await task.value
        XCTAssertEqual(result.code, 15, "The process was not terminated")
        XCTAssertEqual(result.string, "")
    }
}
