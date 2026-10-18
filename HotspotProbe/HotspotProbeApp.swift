import SwiftUI

@main
struct HotspotProbeApp: App {
    @StateObject private var probe = ProbeModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ProbeView(probe: probe)
                .onChange(of: scenePhase) { _, phase in
                    probe.record("生命周期：\(String(describing: phase))")
                }
        }
    }
}
