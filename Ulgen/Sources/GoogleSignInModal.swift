import SwiftUI

/// Google Sign-In & Google Drive Sync Management Modal
public struct GoogleSignInModal: View {
    @ObservedObject var engine = GoogleDriveSyncEngine.shared
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    @State private var tokenInput: String = ""
    @State private var isVerifying: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card
                        VStack(spacing: 10) {
                            GoogleGIconView(size: 38)

                            Text("Google Drive & Eşitleme")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                            Text("Google Drive ile projelerinizi buluta yedekleyin ve tüm cihazlarınızla anlık MQTT kanalında eşitleyin.")
                                .font(.system(size: 12.5))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                        .padding(.vertical, 16)

                        // Status Card
                        if engine.isAuthorized {
                            connectedCard
                        } else {
                            unauthorizedCard
                        }

                        // Drive Structural Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BULUT KLASÖR YAPISI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            VStack(alignment: .leading, spacing: 6) {
                                hierarchyRow(icon: "folder.fill", text: "Ülgen Takip (Kök Klasör)")
                                hierarchyRow(icon: "doc.text.fill", text: "  ├── Ülgen Takip - Tüm Sistem Yedeği.json")
                                hierarchyRow(icon: "folder.fill", text: "  ├── [Proje Başlığı]/")
                                hierarchyRow(icon: "doc.text.fill", text: "  │     ├── Proje Yedeği.json")
                                hierarchyRow(icon: "photo.fill", text: "  │     └── Medyalar/")
                                hierarchyRow(icon: "folder.fill", text: "  └── Paylaşılan Projeler/")
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.card(isDark: repo.isDarkMode))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderSubtle(isDark: repo.isDarkMode), lineWidth: 1))
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Hesap & Bulut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                    .buttonStyle(.scaleSpring(scale: 0.92))
                }
            }
        }
    }

    private var connectedCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#10B981"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Oturum Açıldı")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                    Text(engine.userEmail.isEmpty ? repo.userProfile.email : engine.userEmail)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                }

                Spacer()
            }
            .padding(14)
            .background(Color(hex: "#10B981").opacity(0.12))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#10B981").opacity(0.35), lineWidth: 1))

            // Action Buttons
            VStack(spacing: 10) {
                Button(action: {
                    Haptics.light()
                    Task {
                        try? await engine.syncNow()
                    }
                }) {
                    HStack(spacing: 8) {
                        if engine.isSyncing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(engine.isSyncing ? "Eşitleniyor..." : "Şimdi Eşitle (Drive & MQTT)")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppTheme.primaryStart)
                    .cornerRadius(10)
                }
                .disabled(engine.isSyncing)
                .buttonStyle(.scaleSpring(scale: 0.96))

                Button(action: {
                    Haptics.medium()
                    engine.signOut()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Oturumu Kapat")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color(hex: "#EF4444").opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.scaleSpring(scale: 0.96))
            }
        }
    }

    private var unauthorizedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Google OAuth Yetkilendirme")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

            VStack(alignment: .leading, spacing: 6) {
                Text("Google Drive API Access Token")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                TextField("Bearer / OAuth Erişim Jetonu (ya-29...)", text: $tokenInput, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(10)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#EF4444").opacity(0.12))
                    .cornerRadius(6)
            }

            if let succ = successMessage {
                Text(succ)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color(hex: "#10B981"))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#10B981").opacity(0.12))
                    .cornerRadius(6)
            }

            Button(action: verifyToken) {
                HStack(spacing: 8) {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    Text(isVerifying ? "Doğrulanıyor..." : "Doğrula ve Bağlan")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : AppTheme.primaryStart)
                .cornerRadius(10)
            }
            .disabled(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isVerifying)
            .buttonStyle(.scaleSpring(scale: 0.96))
        }
        .padding(16)
        .background(AppTheme.card(isDark: repo.isDarkMode))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
    }

    private func verifyToken() {
        let clean = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        isVerifying = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let (email, name) = try await engine.verifyAndSaveToken(clean)
                await MainActor.run {
                    self.isVerifying = false
                    self.successMessage = "Bağlantı başarılı: \(email) (\(name))"
                    Haptics.success()
                }
                // Automatically run sync
                try? await engine.syncNow()
            } catch {
                await MainActor.run {
                    self.isVerifying = false
                    self.errorMessage = error.localizedDescription
                    Haptics.error()
                }
            }
        }
    }

    private func hierarchyRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.primary)
            Text(text)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
        }
    }
}
