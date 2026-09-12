import Foundation
import Testing
import XSTooling

@Suite(.gitHub)
struct ShellTests {

    @Test func sh() async throws {
        let shell = Shell.sh
        #expect(shell == Shell(path: "/bin/sh", arguments: []))

        let string = try await shell("echo 'hello world'").read().string
        #expect(string == "hello world")
    }

    @Test func bash() async throws {
        let shell = Shell.bash
        #expect(shell == Shell(path: "/bin/bash", arguments: []))

        let string = try await shell("echo 'hello world'").read().string
        #expect(string == "hello world")
    }

    @Test func zsh() async throws {
        let shell = Shell.zsh
        #expect(shell == Shell(path: "/bin/zsh", arguments: []))

        #if os(macOS)
        let string = try await shell("echo 'hello world'").read().string
        #expect(string == "hello world")
        #endif
    }

    @Test func current() throws {
        var shell = Shell.current
        #expect(shell.arguments == [])

        let expected = try #require(ProcessInfo.processInfo.environment["SHELL"])
        #if os(macOS)
        #expect(shell.path == expected)
        #elseif os(Linux)
        #expect(shell.path == expected)
        #endif

        shell.path = "/bin/sh"
        shell.arguments = ["--verbose"]
        Shell.$current.withValue(shell) {
            let shell = Shell.current
            #expect(shell.path == "/bin/sh")
            #expect(shell.arguments == ["--verbose"])
        }
    }

    @Test func arguments() {
        var shell = Shell.zsh
        shell.arguments = ["--login", "--verbose"]

        let command = shell.command(string: "echo 'hello world'")
        let expected = ProcessCommand(
            path: "/bin/zsh",
            arguments: ["--login", "--verbose", "-c", "echo 'hello world'"]
        )
        #expect(command == expected)
    }

    @Test func version() {
        let shell = Shell.sh

        let command = shell.version
        let expected = ProcessCommand(
            path: "/bin/sh",
            arguments: ["--version"]
        )
        #expect(command == expected)
    }

    @Test func callAsFunction() {
        let shell = Shell.bash
        let command = shell("xcrun xcodebuild -version")

        let expected = ProcessCommand(
            path: "/bin/bash",
            arguments: ["-c", "xcrun xcodebuild -version"]
        )
        #expect(command == expected)
    }
}
