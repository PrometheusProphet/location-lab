import Foundation

@MainActor
final class SimulationController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var status = "Choose an Xcode project to set up device testing."

    private var currentProcess: Process?
    private var runID: UUID?

    func start(city: City, device: ConnectedDevice, projectPath: String, durationSeconds: Int) {
        guard !isRunning else { return }
        let id = UUID()
        runID = id
        isRunning = true
        status = "Preparing the iPhone test runner…"

        Task {
            await execute(id: id, city: city, device: device, projectPath: projectPath, durationSeconds: durationSeconds)
        }
    }

    func stop() {
        guard isRunning else { return }
        runID = nil
        status = "Stopping Xcode session…"
        if currentProcess?.isRunning == true {
            currentProcess?.terminate()
        }
    }

    private func execute(id: UUID, city: City, device: ConnectedDevice, projectPath: String, durationSeconds: Int) async {
        do {
            let projectURL = URL(fileURLWithPath: projectPath)
            guard projectURL.pathExtension == "xcodeproj",
                  FileManager.default.fileExists(atPath: projectURL.path) else {
                throw SimulationError.invalidProject
            }

            let derivedDataURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("LocationLab/DerivedData", isDirectory: true)
            try FileManager.default.createDirectory(at: derivedDataURL, withIntermediateDirectories: true)

            let destination = "platform=iOS,id=\(device.id)"
            let build = try await runXcodebuild([
                "build-for-testing",
                "-project", projectURL.path,
                "-scheme", "Location Spoofer",
                "-destination", destination,
                "-derivedDataPath", derivedDataURL.path,
                "-allowProvisioningUpdates",
                "-allowProvisioningDeviceRegistration",
                "-quiet"
            ])
            guard runID == id else { finishStopped(); return }
            guard build.exitCode == 0 else { throw SimulationError.xcodeFailed(build.output) }

            let testRunURL = try makeTestRun(city: city, durationSeconds: durationSeconds, derivedDataURL: derivedDataURL)
            defer { try? FileManager.default.removeItem(at: testRunURL) }

            let resultsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("LocationLab/TestResults", isDirectory: true)
            try FileManager.default.createDirectory(at: resultsURL, withIntermediateDirectories: true)
            let resultBundleURL = resultsURL.appendingPathComponent("\(id.uuidString).xcresult")

            status = "Xcode test running for \(city.displayName). Check the iPhone helper for its coordinates."
            let test = try await runXcodebuild([
                "test-without-building",
                "-xctestrun", testRunURL.path,
                "-destination", destination,
                "-resultBundlePath", resultBundleURL.path,
                "-only-testing:Location SpooferUITests/LocationSpooferUITests/testHoldSimulatedLocation",
                "-quiet"
            ])
            guard runID == id else { finishStopped(); return }
            if test.exitCode == 0 {
                status = "Test session finished. The device should return to its normal location."
            } else {
                status = SimulationError.xcodeFailed(test.output).localizedDescription
            }
            isRunning = false
            runID = nil
        } catch {
            guard runID == id else { finishStopped(); return }
            status = error.localizedDescription
            isRunning = false
            runID = nil
        }
    }

    private func finishStopped() {
        status = "Xcode session stopped."
        isRunning = false
    }

    private func runXcodebuild(_ arguments: [String]) async throws -> (exitCode: Int32, output: String) {
        let logURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("location-lab-xcode-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        let logHandle = try FileHandle(forWritingTo: logURL)
        defer {
            try? logHandle.close()
            try? FileManager.default.removeItem(at: logURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = arguments
        process.standardOutput = logHandle
        process.standardError = logHandle
        currentProcess = process
        do {
            try process.run()
        } catch {
            currentProcess = nil
            throw error
        }

        let exitCode = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                continuation.resume(returning: process.terminationStatus)
            }
        }
        currentProcess = nil
        let output = String(decoding: (try? Data(contentsOf: logURL)) ?? Data(), as: UTF8.self)
        return (exitCode, output)
    }

    private func makeTestRun(city: City, durationSeconds: Int, derivedDataURL: URL) throws -> URL {
        let productsURL = derivedDataURL.appendingPathComponent("Build/Products", isDirectory: true)
        let candidates = try FileManager.default.contentsOfDirectory(
            at: productsURL, includingPropertiesForKeys: [.contentModificationDateKey]
        ).filter {
            $0.pathExtension == "xctestrun" && $0.lastPathComponent.hasPrefix("Location Spoofer_")
        }
        guard let templateURL = candidates.max(by: {
            ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
                < ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }) else {
            throw SimulationError.missingTestRun
        }

        let data = try Data(contentsOf: templateURL)
        guard var root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              var configurations = root["TestConfigurations"] as? [[String: Any]],
              !configurations.isEmpty,
              var targets = configurations[0]["TestTargets"] as? [[String: Any]],
              !targets.isEmpty else {
            throw SimulationError.invalidTestRun
        }

        var environment = targets[0]["EnvironmentVariables"] as? [String: String] ?? [:]
        environment["LOCATION_LAB_LATITUDE"] = String(city.latitude)
        environment["LOCATION_LAB_LONGITUDE"] = String(city.longitude)
        environment["LOCATION_LAB_CITY"] = city.displayName
        environment["LOCATION_LAB_HOLD_SECONDS"] = String(durationSeconds)
        targets[0]["EnvironmentVariables"] = environment
        configurations[0]["TestTargets"] = targets
        root["TestConfigurations"] = configurations

        let configuredURL = productsURL.appendingPathComponent("LocationLab-\(UUID().uuidString).xctestrun")
        let configuredData = try PropertyListSerialization.data(fromPropertyList: root, format: .xml, options: 0)
        try configuredData.write(to: configuredURL, options: .atomic)
        return configuredURL
    }
}

private enum SimulationError: LocalizedError {
    case invalidProject
    case missingTestRun
    case invalidTestRun
    case xcodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidProject:
            return "Choose the repository's Location Spoofer.xcodeproj first."
        case .missingTestRun, .invalidTestRun:
            return "Xcode did not produce a usable UI-test configuration. Open the project in Xcode and check its test scheme."
        case .xcodeFailed(let output):
            let lines = output.split(separator: "\n")
            let errorLine = lines.last(where: { $0.contains("error:") || $0.contains("Testing failed:") })
            return errorLine.map(String.init) ?? "Xcode could not start the test. Check signing, device connection, and Xcode's report navigator."
        }
    }
}
