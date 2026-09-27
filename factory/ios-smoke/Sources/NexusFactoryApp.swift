import SwiftUI

@main
struct NexusFactoryApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("NEXUS APP FACTORY").font(.title.bold()).foregroundStyle(.cyan)
                    Text("APPLE GATE: ONLINE").font(.system(.body, design: .monospaced)).foregroundStyle(.green)
                }
            }
        }
    }
}
