import CoreLocation
import XCTest

final class LocationSpooferUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHoldSimulatedLocation() async throws {
        let environment = ProcessInfo.processInfo.environment
        let latitude = Double(environment["LOCATION_LAB_LATITUDE"] ?? "") ?? 44.9778
        let longitude = Double(environment["LOCATION_LAB_LONGITUDE"] ?? "") ?? -93.2650
        let holdSeconds = max(Double(environment["LOCATION_LAB_HOLD_SECONDS"] ?? "") ?? 5, 0)

        let app = XCUIApplication()
        app.launchEnvironment["LOCATION_LAB_CITY"] = environment["LOCATION_LAB_CITY"] ?? "Minneapolis, MN"
        XCUIDevice.shared.location = XCUILocation(
            location: CLLocation(latitude: latitude, longitude: longitude)
        )
        app.launch()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowLocation = springboard.alerts.buttons["Allow While Using App"]
        if allowLocation.waitForExistence(timeout: 5) {
            allowLocation.tap()
        }

        let locationLabel = app.staticTexts["current-location"]
        XCTAssertTrue(locationLabel.waitForExistence(timeout: 10))
        let expectedCoordinates = String(format: "%.4f, %.4f", latitude, longitude)
        for _ in 0..<20 where locationLabel.label != expectedCoordinates {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        XCTAssertEqual(locationLabel.label, expectedCoordinates)

        print("LOCATION_LAB_ACTIVE latitude=\(latitude) longitude=\(longitude) holdSeconds=\(holdSeconds)")

        if holdSeconds == 0 {
            while true {
                try await Task.sleep(nanoseconds: 60_000_000_000)
            }
        } else {
            var remainingSeconds = holdSeconds
            while remainingSeconds > 0 {
                let interval = min(remainingSeconds, 60)
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                remainingSeconds -= interval
            }
        }
    }
}
