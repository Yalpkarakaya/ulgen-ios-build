import SwiftUI

public struct MChatView: View {
    public var projectId: String
    public var onDismiss: () -> Void = {}

    @ObservedObject var repo = ProjectRepository.shared
    @State private var activeSessionId: String? = nil
    @State private var inputText: String = ""
    @State private var isGenerating: Bool = false

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    private var sessions: [ChatSession] {
        project?.chatSessions ?? []
    }

    private var activeSession: ChatSession? {
        sessions.first(where: { $0.id == activeSessionId })
    }

    public init(projectId: String, onDismiss: @escaping () -> Void = {}) {
        self.projectId = projectId
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Dark Backdrop Scrim
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Centered Modal Dialog Card (1:1 Android MChatModal)
            VStack(alignment: .leading, spacing: 14) {
                if let session = activeSession {
                    activeSessionView(session)
                } else {
                    sessionListView()
                }
            }
            .padding(18)
            .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color(hex: "#FFFFFF"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(repo.isDarkMode ? Color(hex: "#38332E") : Color(hex: "#E5E0D8"), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - View 1: Session Detail / Messaging
    @ViewBuilder
    private func activeSessionView(_ session: ChatSession) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                Haptics.light()
                activeSessionId = nil
            }) {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title.isEmpty ? "Sohbet" : session.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .lineLimit(1)
                Text("\(session.messages.count) mesaj")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    .frame(width: 28, height: 28)
                    .background(repo.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    .clipShape(Circle())
            }
        }

        Divider()

        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(session.messages) { msg in
                    HStack {
                        if msg.role == "user" {
                            Spacer()
                            Text(msg.content)
                                .font(.system(size: 13.5))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(hex: "#8A4B1A"))
                                .cornerRadius(12)
                        } else {
                            Text(msg.content)
                                .font(.system(size: 13.5))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                .padding(10)
                                .background(repo.isDarkMode ? Color(hex: "#282420") : Color(hex: "#F1F5F9"))
                                .cornerRadius(12)
                            Spacer()
                        }
                    }

                    if isGenerating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(AppTheme.primary)
                            Text("Ülgen AI yanıt üretiyor...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(maxHeight: 380)

        HStack(spacing: 8) {
            TextField("Bir soru sorun...", text: $inputText)
                .font(.system(size: 13.5))
                .padding(10)
                .background(repo.isDarkMode ? Color(hex: "#262320") : Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#8A4B1A"))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - View 2: Sessions List
    @ViewBuilder
    private func sessionListView() -> some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#64748B"))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.scaleSpring(scale: 0.90))

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Medya Sohbetleri")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#FAF8F5") : Color(hex: "#1E293B"))

                Text("\(sessions.count) sohbet mevcut")
                    .font(.system(size: 11.5))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#9E988F") : Color(hex: "#64748B"))
            }

            Spacer()
        }

        // + Yeni Sohbet Başlat Butonu (1:1 Android)
        Button(action: {
            Haptics.light()
            if let p = project {
                let newSession = ChatSession(title: "Yeni Sohbet")
                repo.addChatSession(projectId: p.id, session: newSession)
                activeSessionId = newSession.id
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("Yeni Sohbet Başlat")
                    .font(.system(size: 13.5, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Color(hex: "#8A4B1A"))
            .cornerRadius(10)
        }
        .buttonStyle(.scaleSpring(scale: 0.96))

        // Empty State Card (1:1 Android)
        if sessions.isEmpty {
            VStack(spacing: 12) {
                Spacer().frame(height: 120)

                Image(systemName: "bubble.left")
                    .font(.system(size: 46))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#64748B") : Color(hex: "#94A3B8"))

                Text("Henüz bir sohbet yok.")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#FAF8F5") : Color(hex: "#1E293B"))

                Text("Yukarıdan yeni bir sohbet başlatarak projeniz veya dosyalarınız hakkında AI ile konuşun.")
                    .font(.system(size: 12))
                    .foregroundColor(repo.isDarkMode ? Color(hex: "#9E988F") : Color(hex: "#64748B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 120)
            }
            .frame(maxWidth: .infinity)
            .background(repo.isDarkMode ? Color(hex: "#24201D") : Color(hex: "#F8FAFC"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(repo.isDarkMode ? Color(hex: "#38332E") : Color(hex: "#E2E8F0"), lineWidth: 1)
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sessions) { s in
                        Button(action: {
                            activeSessionId = s.id
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                    Text("\(s.messages.count) mesaj")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            }
                            .padding(12)
                            .background(AppTheme.card(isDark: repo.isDarkMode))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 320)
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let p = project else { return }

        inputText = ""
        repo.addChatMessage(projectId: p.id, role: "user", content: text)
        isGenerating = true

        AiService.shared.sendMessage(project: p, userMessage: text) { result in
            DispatchQueue.main.async {
                self.isGenerating = false
                switch result {
                case .success(let reply):
                    self.repo.addChatMessage(projectId: p.id, role: "assistant", content: reply)
                case .failure(let err):
                    self.repo.addChatMessage(projectId: p.id, role: "assistant", content: "AI Servisi Hatası: \(err.localizedDescription)")
                }
            }
        }
    }
}
