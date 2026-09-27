import SwiftUI

@main
struct LocationLabMacApp: App {
    var body: some Scene {
        WindowGroup("Location Lab") {
            MacContentView()
                .frame(minWidth: 900, minHeight: 620)
        }
    }
}
