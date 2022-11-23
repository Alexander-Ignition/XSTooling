# 🛠 XSTooling 🧰

[![Test](https://github.com/Alexander-Ignition/XSTooling/actions/workflows/test.yml/badge.svg)](https://github.com/Alexander-Ignition/XSTooling/actions/workflows/test.yml)
[![SPM compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Swift 5.3](https://img.shields.io/badge/swift-5.3-brightgreen.svg?style=flat)](https://developer.apple.com/swift)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/Alexander-Ignition/XSTooling/blob/master/LICENSE)

Xcode and Swift toolset

Supported tools:

- shell
- xcrun
- simstl

## Getting Started

To use the `XSTooling` library in a SwiftPM project, add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/Alexander-Ignition/XSTooling", from: "0.0.2"),
```

Include `"XSTooling"` as a dependency for your executable target:

```swift
.target(name: "<target>", dependencies: [
    "XSTooling",
]),
```

Finally, add `import XSTooling` to your source code.

```swift
import XSTooling

let sh = Shell.default
try await sh("swift build").run()
```

## Shell

Shell command can be `run` or `read`.

Read the shell command output.

```swift
let version = try await sh("xcodebuild -version").read().string
```

Run shell command with redirection to stdout and stderr.

```swift
try await sh("ls -al").run()
```

Redirection can be configured, for example, to write to a log file.

```swift
let url = URL(fileURLWithPath: "logs.txt", isDirectory: false)
FileManager.default.createFile(atPath: url.path, contents: nil)
let file = try FileHandle(forWritingTo: url)

try await sh("swift build").run(.output(file).error(file))
```

`Shell` has predefined instances.

```swift
Shell.default
Shell.sh
Shell.bash
Shell.zsh
```

Conceptually, a `Shell` is a wrapper over a `ProcessCommand`. 

- `sh.command` contains common parameters for all commands.
- `sh("ls")` each call to this method returned a copy of the `ProcessCommand` with additional arguments

```swift
let sh = Shell.default
sh.command // ProcessCommand
sh.command.environment // [String: String]?
sh.command.currentDirectoryURL // URL?
sh("ls") // ProcessCommand
```

## ProcessCommand

The main component is `ProcessCommand`. Which can configure and run a subprocess. The `read` and `run` methods are called on the `ProcessCommand`.

```swift
let command = ProcessCommand(
    path: "/usr/bin/xcodebuild",
    arguments: ["-version"]
)
try await command.run()
```

The location of the executable file is not always known. To do this, there is a `find` method that searches for an executable file by name.

```swift
try await ProcessCommand
    .find("xcodebuild")!
    .appending(argument: "-version")
    .run()
```

## simctl

By analogy with Shell, you can make other wrappers over the `ProcessCommand`

`Simctl` (Simulator control tool) is an example of a complex such wrapper

Using simctl, you can search for iPhone 12, turn it on and launch the application.

```swift
let xcrun = XCRun()
let simulator = xcrun.simctl

let list = try await simulator.list(.devices, "iPhone 12", available: true).json.decode()
let devices = list.devices.flatMap { $0.value }

for info in devices where info.state == "Booted" {
    try await simulator.device(info.udid).shutdown.run()
}
            
let udid =  devices.first!.udid
try await simulator.device(udid).boot.run()
try await simulator.device(udid).app("com.example.app").launch.run()
```

## License

MIT
