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
.package(url: "https://github.com/Alexander-Ignition/XSTooling", from: "0.0.1"),
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

let shell = Shell.sh

let path = try shell("pwd").string
let files = try shell("ls").lines
```

## simctl

Simulator control tool.

Fetch Extract the list of devices and filter them by the prefix of the name "iPhone".

```swift
let xcrun = XCRun()
let simulator = try xcrun.simctl()

let devices = try simulator.list().devices(where: { device in
    device.name.hasPrefix("iPhone")
})

devices
```
