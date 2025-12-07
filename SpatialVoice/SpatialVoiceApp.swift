//SpatialVoiceApp
import SwiftUI

@main
struct SpatialVoiceApp: App {
    @StateObject private var session = PresentationSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }

        ImmersiveSpace(id: "ClassPresent1") {
            ClassPresentationImmersiveView(sceneName: "ClassPresent1")
                .environmentObject(session)
        }

        ImmersiveSpace(id: "ClassPresent2") {
            ClassPresentationImmersiveView(sceneName: "ClassPresent2")
                .environmentObject(session)
        }

        ImmersiveSpace(id: "ClassPresent3") {
            ClassPresentationImmersiveView(sceneName: "ClassPresent3")
                .environmentObject(session)
        }

        ImmersiveSpace(id: "ClassPresent4") {
            ClassPresentationImmersiveView(sceneName: "ClassPresent4")
                .environmentObject(session)
        }
        
    }
}
