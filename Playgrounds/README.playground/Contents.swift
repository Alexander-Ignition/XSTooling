/*:
 # 🛠 XSTooling 🧰

 Xcode and Swift toolset

 Supported tools:

 - shell
 - xcrun
 - simstl

 ## Getting Started

 To use the `XSTooling` library in a SwiftPM project, add the following line to the dependencies in your `Package.swift` file:

 ```swift
 .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
 ```

 Include `"XSTooling"` as a dependency for your executable target:

 ```swift
 .target(name: "<target>", dependencies: [
     .product(name: "Algorithms", package: "swift-algorithms"),
 ]),
 ```

 Finally, add `import XSTooling` to your source code.
 */
import XSTooling

let shell = Shell.sh

let path = try shell("pwd").string
let files = try shell("ls").lines

/*:
 ## simctl

 Simulator control tool.

 Fetch Extract the list of devices and filter them by the prefix of the name "iPhone".
 */
let xcrun = XCRun()
let simulator = try xcrun.simctl()

let devices = try simulator.list().devices(where: { device in
    device.name.hasPrefix("iPhone")
})

devices

