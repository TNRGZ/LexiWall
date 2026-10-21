import SwiftUI

@main
struct LexiWallApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .tint(Color(red: 0.24, green: 0.52, blue: 0.45))
        }
    }
}
