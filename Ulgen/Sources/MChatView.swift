import SwiftUI

public struct MChatView: View {
    public var projectId: String
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var isGenerating: Bool = false

    private var project: Project? {
        repo.projects.first(where: { $0.id == projectId })
    }

    private var messages: [ChatMessage] {
        project?.chatSessions.first?.messages ?? []
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat Messages Scroll
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if messages.isEmpty {
                                    aiGreetingCard
                                } else {
                                    ForEach(messages) { msg in
                                        messageBubble(msg)
                                            .id(msg.id)
                                    }
                                }

                                if isGenerating {
                                    HStack {
                                        ProgressView()
                                            .tint(AppTheme.primary)
                                        Text("Ülgen AI yanıt üretiyor...")
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(16)
                        }
                        .onChange(of: messages.count) { _ in
                            if let last = messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider().background(AppTheme.border(isDark: repo.isDarkMode))

                    // Quick Prompt Suggestions
                    quickPromptsBar

                    // Input Bar
                    HStack(spacing: 8) {
                        TextField("Mühendislik sorusu veya analiz isteği...", text: $inputText)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                            .padding(10)
                            .background(AppTheme.card(isDark: repo.isDarkMode))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : AppTheme.primary)
                        }
                        .buttonStyle(.scaleSpring(scale: 0.90))
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
                    }
                    .padding(12)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                }
            }
            .navigationTitle("MChat AI Asistanı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                        .buttonStyle(.scaleSpring(scale: 0.92))
                }
            }
        }
    }

    private var aiGreetingCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(AppTheme.primary)

            Text("Proje Bazlı AI Danışmanı")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

            Text("Bu projeye ait şematik, kod, görev ağacı ve malzeme gereksinimlerini analiz edebilirim.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(24)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.role == "user" { Spacer() }

            VStack(alignment: msg.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(msg.content)
                    .font(.system(size: 14))
                    .foregroundColor(msg.role == "user" ? .white : AppTheme.textHeading(isDark: repo.isDarkMode))
                    .padding(12)
                    .background(
                        msg.role == "user"
                            ? AppTheme.primary
                            : AppTheme.card(isDark: repo.isDarkMode)
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(msg.role == "user" ? AppTheme.primary : AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1)
                    )

                Text(Date(timeIntervalSince1970: Double(msg.timestamp) / 1000).formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 300, alignment: msg.role == "user" ? .trailing : .leading)

            if msg.role == "assistant" { Spacer() }
        }
    }

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                quickPromptChip("BOM Malzeme Listesi") {
                    inputText = "Bu projenin şematik ve güç katı gereksinimlerine göre kritik bileşen BOM listesini oluştur."
                    sendMessage()
                }
                quickPromptChip("Aşamalara Görev Böl") {
                    inputText = "Mevcut aşamalara eklenebilecek test ve doğrulama alt görevlerini listele."
                    sendMessage()
                }
                quickPromptChip("Hata ve Risk Analizi") {
                    inputText = "Bu tasarımda karşılaşılabilecek termal, parazitik ve EMI risklerini analiz et."
                    sendMessage()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func quickPromptChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.primary.opacity(0.12))
                .cornerRadius(16)
        }
        .buttonStyle(.scaleSpring(scale: 0.94))
    }

    private func sendMessage() {
        guard let p = project else { return }
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        inputText = ""
        repo.addChatMessage(projectId: p.id, role: "user", content: prompt)
        Haptics.light()

        isGenerating = true
        AiService.shared.sendMessage(project: p, userMessage: prompt) { result in
            isGenerating = false
            switch result {
            case .success(let answer):
                repo.addChatMessage(projectId: p.id, role: "assistant", content: answer)
                Haptics.success()
            case .failure(let err):
                repo.addChatMessage(projectId: p.id, role: "assistant", content: "AI Hatası: \(err.localizedDescription)")
                Haptics.error()
            }
        }
    }
}
