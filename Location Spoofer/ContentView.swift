import CoreLocation
import SwiftUI

struct ContentView: View {
    @StateObject private var locationReader = LocationReader()

    var body: some View {
        VStack(spacing: 8) {
            Text("Location Lab Helper")
                .font(.title)

            Text("Current test location")
                .foregroundStyle(.secondary)

            Text(locationReader.coordinates)
                .font(.system(.body, design: .monospaced))
                .accessibilityIdentifier("current-location")
        }
        .padding()
        .onAppear { locationReader.start() }
    }
}

final class LocationReader: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var coordinates = "Waiting for location…"

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        coordinates = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        coordinates = "Location unavailable: \(error.localizedDescription)"
    }
}

#Preview {
    ContentView()
}
