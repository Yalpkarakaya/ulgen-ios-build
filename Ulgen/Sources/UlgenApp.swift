import SwiftUI

@main
struct UlgenApp: App {
    @StateObject private var repo = ProjectRepository.shared

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(repo.isDarkMode ? .dark : .light)
        }
    }
}
