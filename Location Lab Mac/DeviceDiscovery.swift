import Foundation

struct ConnectedDevice: Identifiable, Sendable {
    let id: String
    let name: String
    let model: String
    let isReady: Bool
    let detail: String
}

enum DeviceDiscovery {
    private struct DeviceList: Decodable {
        let result: Result

        struct Result: Decodable {
            let devices: [Device]
        }

        struct Device: Decodable {
            let identifier: String
            let connectionProperties: ConnectionProperties
            let deviceProperties: DeviceProperties
            let hardwareProperties: HardwareProperties
        }

        struct ConnectionProperties: Decodable {
            let tunnelState: String?
        }

        struct DeviceProperties: Decodable {
            let name: String
            let ddiServicesAvailable: Bool?
            let developerModeStatus: String?
        }

        struct HardwareProperties: Decodable {
            let platform: String
            let marketingName: String?
        }
    }

    static func listIPhones() throws -> [ConnectedDevice] {
        let jsonURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("location-lab-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: jsonURL) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["devicectl", "list", "devices", "--json-output", jsonURL.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "LocationLab.DeviceDiscovery",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Xcode could not list devices. Check that Xcode is installed and the iPhone is trusted."]
            )
        }

        let response = try JSONDecoder().decode(DeviceList.self, from: Data(contentsOf: jsonURL))
        return response.result.devices
            .filter { $0.hardwareProperties.platform == "iOS" }
            .map { device in
                let ready = device.connectionProperties.tunnelState == "connected"
                    && device.deviceProperties.ddiServicesAvailable == true
                    && device.deviceProperties.developerModeStatus == "enabled"
                let detail: String
                if device.deviceProperties.developerModeStatus != "enabled" {
                    detail = "Enable Developer Mode on this iPhone"
                } else if device.connectionProperties.tunnelState != "connected" {
                    detail = "Developer tunnel unavailable; check VPN and device connection"
                } else if device.deviceProperties.ddiServicesAvailable != true {
                    detail = "Xcode device services are unavailable"
                } else {
                    detail = "Ready for Xcode"
                }
                return ConnectedDevice(
                    id: device.identifier,
                    name: device.deviceProperties.name,
                    model: device.hardwareProperties.marketingName ?? "iPhone",
                    isReady: ready,
                    detail: detail
                )
            }
    }
}
