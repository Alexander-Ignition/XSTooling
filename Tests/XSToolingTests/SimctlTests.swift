import Foundation
import Testing

@testable import XSTooling

@Suite(.gitHub)
struct SimctlTests {
    private let simctl: Simctl
    private let path: String

    init() {
        self.path = "/usr/bin/simctl/\(Test.current!.name)"
        self.simctl = Simctl(path: path)
    }

    private func command(_ arguments: String...) -> ProcessCommand {
        ProcessCommand(path: path, arguments: arguments)
    }

    // MARK: - Device control

    @Test func boot() {
        let actual = simctl.device("2").boot
        let expected = command("boot", "2")
        #expect(actual == expected)
    }

    @Test func shutdown() {
        let actual = simctl.device("2").shutdown
        let expected = command("shutdown", "2")
        #expect(actual == expected)
    }

    @Test func openURL() {
        let actual = simctl.booted.open(url: "https://test.com")
        let expected = command("openurl", "booted", "https://test.com")
        #expect(actual == expected)
    }

    // MARK: - App control

    @Test func launch() {
        let actual = simctl.device("4").app("com.bundle.app").launch
        let expected = command("launch", "4", "com.bundle.app")
        #expect(actual == expected)
    }

    @Test func terminate() {
        let actual = simctl.device("5").app("com.bundle.app2").terminate
        let expected = command("terminate", "5", "com.bundle.app2")
        #expect(actual == expected)
    }

    // MARK: - App container

    @Test func appContainer() {
        let actual = simctl.device("6").app("com.bundle.app3").container.app
        let expected = command("get_app_container", "6", "com.bundle.app3", "app")
        #expect(actual == expected)
    }

    @Test func dataContainer() {
        let actual = simctl.device("7").app("com.bundle.app4").container.data
        let expected = command("get_app_container", "7", "com.bundle.app4", "data")
        #expect(actual == expected)
    }

    @Test func groupsContainer() {
        let actual = simctl.device("8").app("com.bundle.app5").container.groups
        let expected = command("get_app_container", "8", "com.bundle.app5", "groups")
        #expect(actual == expected)
    }

    @Test func groupContainer() {
        let actual = simctl.device("9").app("com.bundle.app6").container.group("g")
        let expected = command("get_app_container", "9", "com.bundle.app6", "g")
        #expect(actual == expected)
    }

    // MARK: - Device list

    @Test func list() {
        let actual = simctl.list.command
        let expected = command("list")
        #expect(actual == expected)
    }

    @Test func listJson() {
        let actual = simctl.list.json.command
        let expected = command("list", "--json")
        #expect(actual == expected)
    }

    #if os(macOS)

    @Test static func decodeListJson() async throws {
        let simctl = try await XCRun.current.simctl
        let deviceList = try await simctl.list.json.decode()
        #expect(!deviceList.devices.isEmpty)
    }

    #endif // os(macOS)

    @Test func deviceListFilter() {
        do {
            let actual = simctl.list(.devices).command
            let expected = command("list", "devices")
            #expect(actual == expected)
        }
        do {
            let actual = simctl.list(.devices, "iPhone 8").command
            let expected = command("list", "devices", "iPhone 8")
            #expect(actual == expected)
        }
        do {
            let actual = simctl.list(.devices, "iPhone 8", available: true).command
            let expected = command("list", "devices", "iPhone 8", "available")
            #expect(actual == expected)
        }
    }

    struct DeviceListTests {
        let deviceList: Simctl.DeviceList

        init() throws {
            let resourceURL = Bundle.module.url(
                forResource: "deviceList",
                withExtension: "json",
                subdirectory: "Fixtures/Simctl",
            )
            let url = try #require(resourceURL)
            let data = try Data(contentsOf: url)
            self.deviceList = try JSONDecoder().decode(Simctl.DeviceList.self, from: data)
        }

        @Test func devicesWhere() throws {
            let devices = deviceList.devices(where: { $0.name.hasPrefix("iPhone") })
            #expect(devices.count == 4)
            #expect(devices.allSatisfy({ $0.name.hasPrefix("iPhone") }))
        }

        @Test func booted() throws {
            let devices = deviceList.booted
            #expect(devices.count == 1)
            #expect(devices.allSatisfy({ $0.state == "Booted" }))
        }

        @Test func `device where state == Booted`() throws {
            let device = deviceList.device(where: { $0.state == "Booted" })
            #expect(device?.state == "Booted")
        }

        @Test func `devices where name iPhone`() throws {
            let devices = deviceList.devices(where: { $0.name.hasPrefix("iPhone") })
            #expect(devices.count == 4)
            #expect(devices.allSatisfy({ $0.name.hasPrefix("iPhone") }))
        }
    }
}
