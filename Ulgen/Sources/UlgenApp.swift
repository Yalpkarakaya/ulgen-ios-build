import SwiftUI

@main
struct UlgenApp: App {
    @StateObject private var repo = ProjectRepository.shared

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .buttonStyle(.scaleSpring(scale: 0.96))
                .preferredColorScheme(repo.isDarkMode ? .dark : .light)
        }
    }
}
