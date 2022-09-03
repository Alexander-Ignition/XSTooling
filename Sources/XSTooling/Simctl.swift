/// Command line utility to control the Simulator.
public struct Simctl: Equatable {
    public var command: ProcessCommand

    public init(command: ProcessCommand) {
        self.command = command
    }

    public var booted: DeviceControl {
        DeviceControl(simulator: self, udid: "booted")
    }

    public func device(_ uuid: String) -> DeviceControl {
        DeviceControl(simulator: self, udid: uuid)
    }

    public struct DeviceControl {
        let simulator: Simctl
        let udid: String

        /// Boot a device or device pair.
        public var boot: ProcessCommand {
            simulator.command.appending(arguments: "boot", udid)
        }

        /// Shutdown a device.
        public var shutdown: ProcessCommand {
            simulator.command.appending(arguments: "shutdown", udid)
        }

        /// Open a URL in a device.
        public func open(url: String) -> ProcessCommand {
            simulator.command.appending(arguments: "openurl", udid, url)
        }

        public func app(_ appBundleIdentifier: String) -> ApplicationControl {
            ApplicationControl(device: self, bundleIdentifier: appBundleIdentifier)
        }
    }

    public struct ApplicationControl {
        let device: DeviceControl
        let bundleIdentifier: String

        /// Installed app's container.
        public var container: Container {
            Container(application: self)
        }

        /// Launch an application by identifier on a device.
        public var launch: ProcessCommand {
            device.simulator.command.appending(arguments: "launch", device.udid, bundleIdentifier)
        }

        /// Terminate an application by identifier on a device.
        public var terminate: ProcessCommand {
            device.simulator.command.appending(arguments: "terminate", device.udid, bundleIdentifier)
        }
    }

    /// Installed app's container.
    public struct Container {
        let application: ApplicationControl

        /// The .app bundle.
        public var app: ProcessCommand { _path("app") }

        /// The application's data container.
        public var data: ProcessCommand { _path("data") }

        /// The App Group containers.
        public var groups: ProcessCommand { _path("groups") }

        /// A specific App Group container.
        public func group(_ identifier: String) -> ProcessCommand {
            _path(identifier)
        }

        private func _path(_ container: String) -> ProcessCommand {
            // Usage: simctl get_app_container <device> <app bundle identifier> [<container>]
            application.device.simulator.command.appending(arguments:
                "get_app_container",
                application.device.udid,
                application.bundleIdentifier,
                container)
        }
    }
}

// MARK: - Device List

extension Simctl {
    /// List available devices, device types, runtimes, and device pairs.
    public var list: ListQuery<Void> {
        ListQuery(command: command.appending(argument: "list"))
    }

    /// List available devices, device types, runtimes, and device pairs.
    ///
    /// Specify one of 'devices', 'devicetypes', 'runtimes', or 'pairs' to list only items of that type.
    /// If a type filter is specified you may also specify a search term. Search terms use a simple case-insensitive
    /// contains check against the item's description. You may use the search term 'available' to only list available items.
    public func list(
        _ key: DeviceList.CodingKeys,
        _ term: String? = nil,
        available: Bool = false
    ) -> ListQuery<Void> {
        var arguments: [String] = ["list", key.rawValue]
        if let term = term {
            arguments.append(term)
        }
        if available {
            arguments.append("available")
        }
        return ListQuery(command: command.appending(arguments: arguments))
    }

    public struct ListQuery<Format> {
        public var command: ProcessCommand

        public func read() async throws -> ProcessOutput {
            try await command.read()
        }

        @discardableResult
        public func run(_ redirection: ProcessRedirection? = nil) async throws -> ProcessOutput {
            try await command.run()
        }
    }
}

extension Simctl.ListQuery where Format == Void {
    /// Output as JSON.
    public var json: Simctl.ListQuery<Simctl.DeviceList> {
        Simctl.ListQuery(command: command.appending(argument: "--json"))
    }
}

extension Simctl.ListQuery where Format == Simctl.DeviceList {
    /// Read and decode output.
    public func decode() async throws -> Simctl.DeviceList {
        try await read().decode(Simctl.DeviceList.self)
    }
}

extension Simctl {
    public struct DeviceList: Codable, Equatable {
        public enum CodingKeys: String, CodingKey {
            case devices
            case deviceTypes = "devicetypes"
        }

        public let devices: [String: [DeviceInfo]]
        public let deviceTypes: [DeviceType]

        public init() {
            devices = [:]
            deviceTypes = []
        }

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

    public struct DeviceType: Codable, Equatable {
        public let minRuntimeVersion: Int
        public let bundlePath: String
        public let maxRuntimeVersion: Int
        public let name: String
        public let identifier: String
        public let productFamily: String
    }
}
