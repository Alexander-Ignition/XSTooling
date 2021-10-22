import XCTest
import XSTooling

final class SimctlTests: ToolTestCase {
    private var simctl: Simctl!

    override func setUp() {
        super.setUp()
        simctl = Simctl(path: path, kernel: kernel)
    }

    // MARK: - Device

    func testDeviceBoot() {
        XCTAssertNoThrow(try simctl.device("2").boot())
        XCTAssertEqual(commands, [["boot", "2"]])
    }

    func testDeviceShutdown() {
        XCTAssertNoThrow(try simctl.device("3").shutdown())
        XCTAssertEqual(commands, [["shutdown", "3"]])
    }

    func testDeviceOpenURL() {
        XCTAssertNoThrow(try simctl.device("0").open(url: "link"))
        XCTAssertEqual(commands, [["openurl", "0", "link"]])
    }

    func testBootedDeviceOpenURL() {
        XCTAssertNoThrow(try simctl.booted.open(url: "https://example-0.com"))
        XCTAssertEqual(commands, [["openurl", "booted", "https://example-0.com"]])
    }

    // MARK: - App

    func testDeviceAppLaunch() {
        output = "com.example.app-0: 11"
        XCTAssertEqual(try simctl.device("4").app("com.example.app-0").launch(), 11)
        XCTAssertEqual(commands, [["launch", "4", "com.example.app-0"]])
    }

    func testDeviceAppTerminate() {
        XCTAssertNoThrow(try simctl.device("5").app("com.example.app-1").terminate())
        XCTAssertEqual(commands, [["terminate", "5", "com.example.app-1"]])
    }

    // MARK: - App container

    func testDeviceAppContainerApp() {
        output = "device/app/container/app"
        XCTAssertEqual(try simctl.device("6").app("com.example.app-2").container.app(), "device/app/container/app")
        XCTAssertEqual(commands, [["get_app_container", "6", "com.example.app-2", "app"]])
    }

    func testDeviceAppContainerData() {
        output = "device/app/container/data"
        XCTAssertEqual(try simctl.device("7").app("com.example.app-3").container.data(), "device/app/container/data")
        XCTAssertEqual(commands, [["get_app_container", "7", "com.example.app-3", "data"]])
    }

    func testDeviceAppContainerGroups() {
        output = "device/app/container/groups"
        XCTAssertEqual(try simctl.device("8").app("com.example.app-4").container.groups(), "device/app/container/groups")
        XCTAssertEqual(commands, [["get_app_container", "8", "com.example.app-4", "groups"]])
    }

    func testDeviceAppContainerGroup() {
        output = "device/app/container/group/g"
        XCTAssertEqual(try simctl.device("8").app("com.example.app-4").container.group("g"), "device/app/container/group/g")
        XCTAssertEqual(commands, [["get_app_container", "8", "com.example.app-4", "g"]])
    }

    // MARK: - Device list

    func testDeviceList() throws {
        output = ProcessOutput(data: try readDeviceListData())
        let deviceList = try JSONDecoder().decode(Simctl.DeviceList.self, from: output.data)
        XCTAssertEqual(try simctl.list(), deviceList)
        XCTAssertEqual(commands, [["list", "--json"]])
    }

    func testDeviceListFilter() {
        output = "{}"
        let list = Simctl.DeviceList()
        XCTAssertEqual(try simctl.list(.devices, options: .available, "iPhone 8"), list)
        XCTAssertEqual(commands, [["list", "--json", "devices", "iPhone 8", "available"]])
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

    private func readDeviceListData() throws -> Data {
        let url = Bundle.module.url(forResource: "deviceList", withExtension: "json", subdirectory: "Fixtures/Simctl")
        let validUrl = try XCTUnwrap(url)
        return try Data(contentsOf: validUrl)
    }

    private func readDeviceList() throws -> Simctl.DeviceList {
        let data = try readDeviceListData()
        return try JSONDecoder().decode(Simctl.DeviceList.self, from: data)
    }
}
