# Location Lab

Location Lab is an open-source **developer utility** for simulating a selected city-center location on your own iPhone through Xcode's UI-testing facilities. It is a macOS app with a minimal iPhone helper and 35 built-in US cities. The Mac app also previews locations on a map and exports GPX waypoints. This is not a standalone iPhone app that changes system location without a Mac and Xcode.

The original Personal Team prototype used a different bundle ID. The helper in this repository is called **Location Lab Helper** on the iPhone so installing it does not replace the prototype.

## Requirements

- A Mac with Xcode installed and an Apple development team signed in to Xcode.
- An iPhone connected to and trusted by the Mac, with Developer Mode enabled.
- A working Xcode device connection. If the iPhone looks paired but unavailable, unlock it, reconnect it, and check whether a VPN is blocking Xcode's device tunnel.

The project is configured for the original developer's team. Other builders must select their own team for all three targets in **Signing & Capabilities** and, if necessary, choose unique bundle identifiers. No certificate or provisioning profile is stored in this repository.

## Run and set a city

1. Open `Location Spoofer.xcodeproj` in Xcode.
2. Select the **Location Lab** scheme, choose **My Mac**, and press **Run**.
3. In Location Lab, click **Choose Project…** and select the same `Location Spoofer.xcodeproj` file. This path is remembered locally.
4. Connect and unlock the iPhone. Click **Refresh** if it does not appear as **Ready for Xcode**.
5. Select a city, choose a preset or **Custom** number of minutes, or choose **Until stopped**. Click **Set iPhone to…**. The first run can take a while because Xcode builds and installs the helper and UI-test runner.
6. Check the Location Lab Helper on the iPhone for the selected coordinates. Press **Stop** in the Mac app to end the session. To switch cities, stop the current session, choose another city, and start again.

Location Lab uses `xcodebuild build-for-testing`, then runs a UI test that sets `XCUIDevice.shared.location` to the chosen coordinates and keeps the test alive. A duration is a *simulation session*, not a requirement to wait that long for a test result. **Until stopped** has no timer in this app, but iOS/Xcode may still end a long session if the test runner, Mac app, device connection, or Xcode service stops. Do not rely on this for a critical or unattended workflow.

The Mac app's **Export GPX** button saves a waypoint for manual Xcode simulation. `Location Spoofer/Minneapolis.gpx` is included. To use one manually, run the iPhone helper from Xcode and choose **Debug → Simulate Location →** the GPX waypoint.

## Verified behavior and limits

The macOS app built successfully, and its Set button launched a signed UI test on a physical iPhone 16 Pro. A completed short Seattle session passed the helper's coordinate assertion. A live Minneapolis session logged Xcode setting `44.9778, -93.2650` and the helper reaching its matching coordinate check. Long custom and Until stopped sessions have not been endurance-tested. The tool depends on Xcode's development workflow and should not be represented as an App Store-ready device-wide location switcher.

## Distribution and privacy

The source can be cloned and built with Xcode. No prebuilt Mac app is packaged or notarized here. An iPhone helper from GitHub still needs Apple signing and an appropriate installation path (for example, Xcode on a registered device); downloading source is not the same as installing an App Store app.

Location Lab has no account, analytics SDK, or app-operated server. It remembers the selected Xcode project path on the Mac. The iPhone helper requests when-in-use location access so it can display the coordinates it receives. The map uses Apple's MapKit service, which loads map data for the selected region. Device discovery and testing use local Xcode tools. City coordinates are approximate city-center reference points, not precise addresses.

Use location simulation only on devices and services you are authorized to test. Platform and third-party service rules may differ; this project does not guarantee that a particular use is permitted.

## License

MIT. See [LICENSE](LICENSE). Apple, iPhone, and Xcode are used descriptively; this project is not affiliated with Apple.
