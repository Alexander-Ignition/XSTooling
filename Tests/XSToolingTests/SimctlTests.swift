#if os(macOS)

import XCTest
@testable import XSTooling

final class SimctlTests: GHTestCase {
    private var simctl: Simctl!
    private var path: String!

    override func setUp() {
        super.setUp()
        path = "/usr/bin/simctl/\(name)"
        simctl = Simctl(path: path)
    }

    // MARK: - Device control

    func testDeviceBoot() {
        let command = simctl.device("2").boot

        let expected = ProcessCommand(path: path, arguments: ["boot", "2"])
        XCTAssertEqual(command, expected)
    }

    func testDeviceShutdown() {
        let command = simctl.device("3").shutdown

        let expected = ProcessCommand(path: path, arguments: ["shutdown", "3"])
        XCTAssertEqual(command, expected)
    }

    func testDeviceOpenURL() {
        let command = simctl.device("4").open(url: "https://example.com")

        let expected = ProcessCommand(
            path: path,
            arguments: ["openurl", "4", "https://example.com"]
        )
        XCTAssertEqual(command, expected)
    }

    func testBootedDeviceOpenURL() {
        let command = simctl.booted.open(url: "https://test.com")

        let expected = ProcessCommand(
            path: path,
            arguments: ["openurl", "booted", "https://test.com"]
        )
        XCTAssertEqual(command, expected)
    }

    // MARK: - App control

    func testDeviceAppLaunch() {
        let command = simctl.device("4").app("com.bundle.app").launch

        let expected = ProcessCommand(
            path: path,
            arguments: ["launch", "4", "com.bundle.app"]
        )
        XCTAssertEqual(command, expected)
    }

    func testDeviceAppTerminate() {
        let command = simctl.device("5").app("com.bundle.app2").terminate

        let expected = ProcessCommand(
            path: path,
            arguments: ["terminate", "5", "com.bundle.app2"]
        )
        XCTAssertEqual(command, expected)
    }

    // MARK: - App container

    func testDeviceAppContainerApp() {
        let command = simctl.device("6").app("com.bundle.app3").container.app

        let expected = ProcessCommand(
            path: path,
            arguments: ["get_app_container", "6", "com.bundle.app3", "app"]
        )
        XCTAssertEqual(command, expected)
    }

    func testDeviceAppContainerData() {
        let command = simctl.device("7").app("com.bundle.app4").container.data

        let expected = ProcessCommand(
            path: path,
            arguments: ["get_app_container", "7", "com.bundle.app4", "data"]
        )
        XCTAssertEqual(command, expected)
    }

    func testDeviceAppContainerGroups() {
        let command = simctl.device("8").app("com.bundle.app5").container.groups

        let expected = ProcessCommand(
            path: path,
            arguments: ["get_app_container", "8", "com.bundle.app5", "groups"]
        )
        XCTAssertEqual(command, expected)
    }

    func testDeviceAppContainerGroup() {
        let command = simctl.device("9").app("com.bundle.app6").container.group("g")

        let expected = ProcessCommand(
            path: path,
            arguments: ["get_app_container", "9", "com.bundle.app6", "g"]
        )
        XCTAssertEqual(command, expected)
    }

    // MARK: - Device list

    func testDeviceList() {
        let command = simctl.list.command

        let expected = ProcessCommand(path: path, arguments: ["list"])
        XCTAssertEqual(command, expected)
    }

    func testDeviceListJson() {
        let command = simctl.list.json.command

        let expected = ProcessCommand(path: path, arguments: ["list", "--json"])
        XCTAssertEqual(command, expected)
    }

    func testDeviceListJsonDecode() async throws {
        simctl = try await XCRun.current.simctl
        let deviceList = try await simctl.list.json.decode()
        XCTAssertFalse(deviceList.devices.isEmpty)
    }

    func testDeviceListFilter() {
        var command = simctl.list(.devices).command
        XCTAssertEqual(command, ProcessCommand(path: path, arguments: ["list", "devices"]))

        command = simctl.list(.devices, "iPhone 8").command
        XCTAssertEqual(command, ProcessCommand(path: path, arguments: ["list", "devices", "iPhone 8"]))

        command = simctl.list(.devices, available: true).command
        XCTAssertEqual(command, ProcessCommand(path: path, arguments: ["list", "devices", "available"]))
    }

    func testDeviceListBooted() throws {
        let deviceList = try readDeviceList()
        let devices = deviceList.booted
        XCTAssertEqual(devices.count, 1)
        XCTAssertTrue(devices.allSatisfy({ $0.state == "Booted" }))
    }

    func testDeviceListDeviceWhere() throws {
        let deviceList = try readDeviceList()
        let device = deviceList.device(where: { $0.state == "Booted" })
        XCTAssertEqual(device?.state, "Booted")
    }

    func testDeviceListDevicesWhere() throws {
        let deviceList = try readDeviceList()
        let devices = deviceList.devices(where: { $0.name.hasPrefix("iPhone") })
        XCTAssertEqual(devices.count, 4)
        XCTAssertTrue(devices.allSatisfy({ $0.name.hasPrefix("iPhone") }))
    }

    private func readDeviceList() throws -> Simctl.DeviceList {
        let url = Bundle.module.url(
            forResource: "deviceList",
            withExtension: "json",
            subdirectory: "Fixtures/Simctl")
        let validUrl = try XCTUnwrap(url)
        let data = try Data(contentsOf: validUrl)
        return try JSONDecoder().decode(Simctl.DeviceList.self, from: data)
    }
}

#endif // os(macOS)
