import RTXOnCore
import SwiftUI

@main
struct RTXOnApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(Theme.green)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack(path: Bindable(appState).path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .chapter(let chapter):
                        ChapterView(chapter: chapter)
                    case .level(let id):
                        if let level = LevelPack.level(id: id) {
                            PuzzleView(level: level)
                        }
                    case .daily(let day):
                        PuzzleView(level: Daily.level(day: day))
                    case .smi:
                        SMIView()
                    case .about:
                        AboutView()
                    }
                }
        }
        .background(Theme.background)
    }
}

enum Route: Hashable {
    case chapter(Chapter)
    case level(String)
    case daily(Int)
    case smi
    case about
}
