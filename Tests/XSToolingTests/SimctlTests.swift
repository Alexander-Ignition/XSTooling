import XCTest
import XSTooling

#if os(macOS)

final class SimctlTests: GHTestCase {
    private var simctl: Simctl!
    private var path: String!

    override func setUp() {
        super.setUp()
        path = "/usr/bin/simctl/\(name)"
        simctl = Simctl(command: ProcessCommand(path: path))
    }

    // MARK: - Device control

    func testDeviceBoot() {
        let command = simctl.device("2").boot

        command.assert.equal(path: path, arguments: "boot", "2")
    }

    func testDeviceShutdown() {
        let command = simctl.device("3").shutdown

        command.assert.equal(path: path, arguments: "shutdown", "3")
    }

    func testDeviceOpenURL() {
        let command = simctl.device("device-udid").open(url: "https://example.com")

        command.assert.equal(path: path, arguments: "openurl", "device-udid", "https://example.com")
    }

    func testBootedDeviceOpenURL() {
        let command = simctl.booted.open(url: "https://test.com")

        command.assert.equal(path: path, arguments: "openurl", "booted", "https://test.com")
    }

    // MARK: - App control

    func testDeviceAppLaunch() {
        let command = simctl.device("4").app("com.bundle.app").launch

        command.assert.equal(path: path, arguments: "launch", "4", "com.bundle.app")
    }

    func testDeviceAppTerminate() {
        let command = simctl.device("5").app("com.bundle.app2").terminate

        command.assert.equal(path: path, arguments: "terminate", "5", "com.bundle.app2")
    }

    // MARK: - App container

    func testDeviceAppContainerApp() {
        let command = simctl.device("6").app("com.bundle.app3").container.app

        command.assert.equal(path: path, arguments: "get_app_container", "6", "com.bundle.app3", "app")
    }

    func testDeviceAppContainerData() {
        let command = simctl.device("7").app("com.bundle.app4").container.data

        command.assert.equal(path: path, arguments: "get_app_container", "7", "com.bundle.app4", "data")
    }

    func testDeviceAppContainerGroups() {
        let command = simctl.device("8").app("com.bundle.app5").container.groups

        command.assert.equal(path: path, arguments: "get_app_container", "8", "com.bundle.app5", "groups")
    }

    func testDeviceAppContainerGroup() {
        let command = simctl.device("9").app("com.bundle.app6").container.group("g")

        command.assert.equal(path: path, arguments: "get_app_container", "9", "com.bundle.app6", "g")
    }

    // MARK: - Device list

    func testDeviceList() {
        let command = simctl.list.command

        command.assert.equal(path: path, arguments: "list")
    }

    func testDeviceListJson() {
        let command = simctl.list.json.command

        command.assert.equal(path: path, arguments: "list", "--json")
    }

    func testDeviceListJsonDecode() async {
        simctl = XCRun().simctl
        do {
            let deviceList = try await simctl.list.json.decode()
            XCTAssertFalse(deviceList.devices.isEmpty)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testDeviceListFilter() {
        var command = simctl.list(.devices).command
        command.assert.equal(path: path, arguments: "list", "devices")

        command = simctl.list(.devices, "iPhone 8").command
        command.assert.equal(path: path, arguments: "list", "devices", "iPhone 8")

        command = simctl.list(.devices, available: true).command
        command.assert.equal(path: path, arguments: "list", "devices", "available")
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
