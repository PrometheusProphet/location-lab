import AppKit
import MapKit
import SwiftUI

private enum SessionChoice: String, CaseIterable {
    case fiveMinutes = "5 minutes"
    case fifteenMinutes = "15 minutes"
    case oneHour = "1 hour"
    case custom = "Custom"
    case untilStopped = "Until stopped"
}

struct MacContentView: View {
    @AppStorage("xcodeProjectPath") private var projectPath = ""
    @StateObject private var simulation = SimulationController()
    @State private var searchText = ""
    @State private var selectedCityID = "minneapolis"
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 44.9778, longitude: -93.2650),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    )
    @State private var devices: [ConnectedDevice] = []
    @State private var selectedDeviceID: String?
    @State private var sessionChoice = SessionChoice.fifteenMinutes
    @State private var customMinutes = 90
    @State private var isRefreshing = false
    @State private var deviceError: String?
    @State private var exportError: String?
    @State private var projectError: String?

    private var filteredCities: [City] {
        guard !searchText.isEmpty else { return CityCatalog.cities }
        return CityCatalog.cities.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedCity: City {
        CityCatalog.cities.first { $0.id == selectedCityID }
            ?? CityCatalog.cities.first { $0.id == "minneapolis" }!
    }

    private var selectedDevice: ConnectedDevice? {
        devices.first { $0.id == selectedDeviceID }
    }

    private var canStart: Bool {
        !simulation.isRunning && selectedDevice?.isReady == true && !projectPath.isEmpty
            && (sessionChoice != .custom || (customMinutes > 0 && customMinutes <= Int.max / 60))
    }

    private var sessionSeconds: Int {
        switch sessionChoice {
        case .fiveMinutes: 5 * 60
        case .fifteenMinutes: 15 * 60
        case .oneHour: 60 * 60
        case .custom: customMinutes * 60
        case .untilStopped: 0
        }
    }

    var body: some View {
        NavigationSplitView {
            List(filteredCities, selection: $selectedCityID) { city in
                Label(city.displayName, systemImage: "mappin")
                    .tag(city.id)
            }
            .navigationTitle("US cities")
            .searchable(text: $searchText, prompt: "Search cities")
            .frame(minWidth: 230)
        } detail: {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(selectedCity.displayName)
                            .font(.largeTitle.bold())
                        Text("\(selectedCity.latitude), \(selectedCity.longitude)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Export GPX") { exportGPX() }
                        .buttonStyle(.borderedProminent)
                }

                Map(position: $mapPosition) {
                    Marker(selectedCity.displayName, coordinate: selectedCity.coordinate)
                }
                .mapStyle(.standard)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Text("iPhone")
                        .font(.headline)
                    Spacer()
                    Button("Refresh") { refreshDevices() }
                        .disabled(isRefreshing)
                }

                if let deviceError {
                    Label(deviceError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else if devices.isEmpty {
                    Text(isRefreshing ? "Checking for devices…" : "No iPhone found. Connect and unlock your iPhone, then refresh.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(devices) { device in
                        Button {
                            selectedDeviceID = device.id
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: selectedDeviceID == device.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedDeviceID == device.id ? .green : .secondary)
                                VStack(alignment: .leading) {
                                    Text("\(device.name) · \(device.model)")
                                    Text(device.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(simulation.isRunning)
                    }
                }

                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Xcode project")
                            .font(.headline)
                        Text(projectPath.isEmpty ? "Choose Location Spoofer.xcodeproj" : URL(fileURLWithPath: projectPath).lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(projectPath.isEmpty ? "Choose Project…" : "Change…") { chooseProject() }
                        .disabled(simulation.isRunning)
                }

                HStack {
                    Picker("Session", selection: $sessionChoice) {
                        ForEach(SessionChoice.allCases, id: \.self) { choice in
                            Text(choice.rawValue).tag(choice)
                        }
                    }
                    .frame(maxWidth: 250)
                    .disabled(simulation.isRunning)
                    if sessionChoice == .custom {
                        TextField("Minutes", value: $customMinutes, format: .number)
                            .frame(width: 80)
                            .disabled(simulation.isRunning)
                        Text("minutes")
                    }
                    Spacer()
                }

                HStack {
                    Button("Set iPhone to \(selectedCity.name)") {
                        guard let selectedDevice else { return }
                        simulation.start(
                            city: selectedCity,
                            device: selectedDevice,
                            projectPath: projectPath,
                            durationSeconds: sessionSeconds
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStart)

                    if simulation.isRunning {
                        Button("Stop") { simulation.stop() }
                    }
                }

                Label(simulation.status, systemImage: simulation.isRunning ? "location.fill" : "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Uses Xcode's UI-test location simulation. Keep this Mac and iPhone connected. Long sessions can end if Xcode or the device connection stops.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .navigationTitle("Location Lab")
        }
        .onChange(of: selectedCityID) { _, _ in
            mapPosition = .region(
                MKCoordinateRegion(
                    center: selectedCity.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                )
            )
        }
        .task { refreshDevices() }
        .alert("Could not export GPX", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "Unknown error")
        }
        .alert("Choose an Xcode project", isPresented: Binding(
            get: { projectError != nil },
            set: { if !$0 { projectError = nil } }
        )) {
            Button("OK", role: .cancel) { projectError = nil }
        } message: {
            Text(projectError ?? "Unknown error")
        }
    }

    private func chooseProject() {
        let panel = NSOpenPanel()
        panel.message = "Choose this repository's Location Spoofer.xcodeproj"
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard url.pathExtension == "xcodeproj" else {
            projectError = "Select Location Spoofer.xcodeproj, not a folder or source file."
            return
        }
        projectPath = url.path
    }

    private func exportGPX() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(selectedCity.name.replacingOccurrences(of: " ", with: "")).gpx"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try selectedCity.gpx.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func refreshDevices() {
        isRefreshing = true
        deviceError = nil
        Task {
            do {
                devices = try await Task.detached(priority: .userInitiated) {
                    try DeviceDiscovery.listIPhones()
                }.value
                if !devices.contains(where: { $0.id == selectedDeviceID }) {
                    selectedDeviceID = devices.first(where: \.isReady)?.id ?? devices.first?.id
                }
            } catch {
                devices = []
                deviceError = error.localizedDescription
            }
            isRefreshing = false
        }
    }
}
