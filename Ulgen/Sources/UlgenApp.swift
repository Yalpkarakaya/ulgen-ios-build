import SwiftUI

@main
struct UlgenApp: App {
    @StateObject private var repo = ProjectRepository.shared

    var screenArg: String {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-screen"), idx + 1 < args.count {
            return args[idx + 1]
        }
        return ""
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if screenArg == "detail" {
                    NavigationStack {
                        DetailView(projectId: "p-kotlin-compose")
                    }
                } else if screenArg == "media" {
                    NavigationStack {
                        DetailView(projectId: "p-kotlin-compose", initialModal: "media")
                    }
                } else if screenArg == "mchat" {
                    NavigationStack {
                        DetailView(projectId: "p-kotlin-compose", initialModal: "mchat")
                    }
                } else if screenArg == "coming_soon" {
                    ZStack {
                        DashboardView(initialScreen: "coming_soon")
                        ComingSoonModal(
                            featureName: "İstatistikler",
                            isDarkMode: repo.isDarkMode,
                            onDismiss: {}
                        )
                    }
                } else {
                    DashboardView(initialScreen: screenArg)
                }
            }
            .buttonStyle(.scaleSpring(scale: 0.96))
            .preferredColorScheme(repo.isDarkMode ? .dark : .light)
        }
    }
}
