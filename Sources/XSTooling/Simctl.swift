/// Command line utility to control the Simulator.
public struct Simctl: Tool {
    public let path: String
    public let kernel: Kernel

    public init(path: String, kernel: Kernel) {
        self.path = path
        self.kernel = kernel
    }

    public var booted: Device {
        Device(simctl: self, udid: "booted")
    }

    public func device(_ uuid: String) -> Device {
        Device(simctl: self, udid: uuid)
    }

    public struct Device {
        let simctl: Simctl
        let udid: String

        /// Boot a device or device pair.
        public func boot() throws {
            try simctl.execute("boot", udid)
        }

        /// Shutdown a device.
        public func shutdown() throws {
            try simctl.execute("shutdown", udid)
        }

        /// Open a URL in a device.
        public func open(url: String) throws {
            try simctl.execute("openurl", udid, url)
        }

        public func app(_ appBundleIdentifier: String) -> Application {
            Application(device: self, appBundleIdentifier: appBundleIdentifier)
        }
    }

    public struct Application {
        let device: Device
        let appBundleIdentifier: String

        public var container: Container {
            Container(application: self)
        }

        /// Launch an application by identifier on a device.
        @discardableResult
        public func launch() throws -> Int? {
            let output = try device.simctl.execute("launch", device.udid, appBundleIdentifier)
            // <app_bundle_identifier>: <process_id>
            return output.string.split(separator: " ").last.flatMap { Int($0) }
        }

        /// Terminate an application by identifier on a device.
        public func terminate() throws {
            try device.simctl.execute("terminate", device.udid, appBundleIdentifier)
        }
    }

    /// Installed app's container.
    public struct Container {
        let application: Application

        /// The .app bundle.
        public func app() throws -> String {
            try run("app")
        }

        /// The application's data container.
        public func data() throws -> String {
            try run("data")
        }

        /// The App Group containers.
        public func groups() throws -> String {
            try run("groups")
        }

        /// A specific App Group container.
        public func group(_ identifier: String) throws -> String {
            try run(identifier)
        }

        private func run(_ container: String) throws -> String {
            let device = application.device
            let appId = application.appBundleIdentifier
            // Usage: simctl get_app_container <device> <app bundle identifier> [<container>]
            return try device.simctl.execute("get_app_container", device.udid, appId, container).string
        }
    }
}

// MARK: - Device List

extension Simctl {
    /// List available devices, device types, runtimes, and device pairs.
    ///
    /// - Throws: `ProcessError`.
    /// - Returns: A new `DeviceList`.
    public func list() throws -> DeviceList {
        return try execute("list", "--json").decode(DeviceList.self)
    }

    /// List available devices, device types, runtimes, or device pairs.
    ///
    /// - Parameters:
    ///   - key: Specify one of `.devices`, `.deviceTypes`, `.runtimes`, or `.pairs` to list only items of that type.
    ///   - options: Search options. Default: `.available`.
    ///   - search: If a type filter is specified you may also specify a search term. Search terms use a simple case-insensitive contains check against the item's description.
    /// - Throws: `ProcessError`.
    /// - Returns: A new `DeviceList`.
    public func list(
        _ key: DeviceList.CodingKeys,
        options: DeviceList.Options = .available,
        _ search: String? = nil
    ) throws -> DeviceList {
        // Usage: simctl list [-j | --json] [-v] [devices|devicetypes|runtimes|pairs] [<search term>|available]
        var arguments = ["list", "--json", key.rawValue]

        if let search = search {
            arguments.append(search)
        }
        if options.contains(.available) {
            arguments.append("available")
        }
        let output = try execute(arguments: arguments)
        let list = try output.decode(DeviceList.self)
        return list
    }

    public struct DeviceList: Codable {
        /// Search options.
        public struct Options: OptionSet {
            public let rawValue: Int

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }

            /// You may use the search term 'available' to only list available items.
            public static let available = Options(rawValue: 1)
        }

        public enum CodingKeys: String, CodingKey {
            case devices
            case deviceTypes = "devicetypes"
        }

        public let devices: [String: [DeviceInfo]]
        public let deviceTypes: [DeviceType]

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.devices = try container.decodeIfPresent([String: [DeviceInfo]].self, forKey: .devices) ?? [:]
            self.deviceTypes = try container.decodeIfPresent([DeviceType].self, forKey: .deviceTypes) ?? []
        }

        public var booted: [DeviceInfo] {
            devices(where: { $0.state == "Booted" })
        }

        public func devices(where predicate: (DeviceInfo) -> Bool) -> [DeviceInfo] {
            devices.flatMap { $0.value.filter(predicate) }
        }

        public func device(where predicate: (DeviceInfo) -> Bool) -> DeviceInfo? {
            for (_, group) in devices {
                for device in group where predicate(device) {
                    return device
                }
            }
            return nil
        }
    }

    public struct DeviceInfo: Codable, Equatable {
        public let dataPath: String
        public let logPath: String
        public let udid: String
        public let isAvailable: Bool
        public let deviceTypeIdentifier: String?
        public let state: String
        public let name: String
    }

    public struct DeviceType: Codable {
        public let minRuntimeVersion: Int
        public let bundlePath: String
        public let maxRuntimeVersion: Int
        public let name: String
        public let identifier: String
        public let productFamily: String
    }
}
