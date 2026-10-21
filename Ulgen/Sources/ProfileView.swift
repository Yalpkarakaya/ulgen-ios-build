import SwiftUI

public struct ProfileView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var mqtt = MqttSyncEngine.shared
    @Environment(\.dismiss) private var dismiss

    // Profile state
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var usernameStatus: String = ""
    @State private var isCheckingUsername: Bool = false
    @State private var isUsernameAvailable: Bool = true

    // Sync state
    @State private var syncEmailInput: String = ""
    @State private var isSyncing: Bool = false
    @State private var syncStatusMessage: String? = nil

    // AI Keys state
    @State private var geminiKey: String = ""
    @State private var openaiKey: String = ""
    @State private var claudeKey: String = ""
    @State private var deepseekKey: String = ""
    @State private var selectedModel: String = "gemini-2.0-flash"
    @State private var showGeminiKey: Bool = false
    @State private var showOpenAiKey: Bool = false
    @State private var showClaudeKey: Bool = false
    @State private var showDeepseekKey: Bool = false

    // Alerts
    @State private var showResetAlert: Bool = false
    @State private var saveSuccessMessage: String? = nil

    private let availableModels = [
        "gemini-2.0-flash",
        "gemini-1.5-pro",
        "gpt-4o",
        "claude-3-5-sonnet",
        "deepseek-chat"
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // MARK: - Header
                        headerCard

                        // MARK: - 1. User Profile Section
                        userProfileSection

                        // MARK: - 2. Cloud & Device Sync Section
                        cloudSyncSection

                        // MARK: - 3. AI API Pool Section
                        aiPoolSection

                        // MARK: - 4. Data Management & Reset Section
                        dataManagementSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profil & Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
            .alert("Tüm Verileri Sıfırla", isPresented: $showResetAlert) {
                Button("İptal", role: .cancel) {}
                Button("Tümünü Sil", role: .destructive) {
                    repo.resetAllData()
                    Haptics.success()
                }
            } message: {
                Text("Bu işlem cihazdaki tüm projeleri, bildirimleri ve yerel verileri kalıcı olarak silecektir. Bu işlem geri alınamaz.")
            }
        }
    }

    private func loadCurrentValues() {
        self.displayName = repo.userProfile.displayName
        self.username = repo.userProfile.username
        self.email = repo.userProfile.email
        self.syncEmailInput = repo.userProfile.email.isEmpty ? mqtt.userEmail : repo.userProfile.email

        self.geminiKey = repo.apiKeys.geminiApiKey
        self.openaiKey = repo.apiKeys.openaiApiKey
        self.claudeKey = repo.apiKeys.claudeApiKey
        self.deepseekKey = repo.apiKeys.deepseekApiKey
        self.selectedModel = repo.apiKeys.preferredModel
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profil & AI API Havuzu")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.primaryHeader(isDark: repo.isDarkMode))

            Text("Kullanıcı bilgileri, çoklu AI anahtar yönetimi ve bulut senkronizasyonu")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
        }
        .padding(.vertical, 4)
    }

    // MARK: - 1. User Profile Section
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("KULLANICI BİLGİLERİ")

            HStack(spacing: 16) {
                // Avatar with initials
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)

                    Text(avatarInitials)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName.isEmpty ? "İsimsiz Kullanıcı" : displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                    Text(username.isEmpty ? "@kullanici" : "@\(username.replacingOccurrences(of: "@", with: ""))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.primary)

                    if !email.isEmpty {
                        Text(email)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    }
                }

                Spacer()
            }
            .padding(.bottom, 6)

            Divider().background(AppTheme.border(isDark: repo.isDarkMode))

            // Display Name Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Ad Soyad")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                TextField("Adınız ve soyadınız", text: $displayName)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            // Username Field with Cloud check
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Kullanıcı Adı")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                    Spacer()

                    if isCheckingUsername {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if !usernameStatus.isEmpty {
                        Text(usernameStatus)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isUsernameAvailable ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                    }
                }

                HStack {
                    Text("@")
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    TextField("kullanici_adi", text: $username)
                        .font(.system(size: 14))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: username) { newValue in
                            checkUsernameDebounced(newValue)
                        }
                }
                .padding(10)
                .background(AppTheme.card(isDark: repo.isDarkMode))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            // Email Field
            VStack(alignment: .leading, spacing: 4) {
                Text("E-posta Adresi")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                TextField("ornek@eposta.com", text: $email)
                    .font(.system(size: 14))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .padding(10)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            // Save Profile Button
            Button(action: saveUserProfile) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("Profili Kaydet")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppTheme.primary)
                .cornerRadius(10)
            }
            .buttonStyle(.scaleSpring(scale: 0.97))

            if let msg = saveSuccessMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#10B981"))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    private var avatarInitials: String {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "Ü" }
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2, let f = parts.first?.prefix(1), let l = parts.last?.prefix(1) {
            return "\(f)\(l)".uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private func checkUsernameDebounced(_ val: String) {
        let clean = val.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard !clean.isEmpty else {
            usernameStatus = ""
            return
        }
        isCheckingUsername = true
        Task {
            let res = await CloudflareSyncService.checkUsername(clean)
            await MainActor.run {
                self.isCheckingUsername = false
                self.isUsernameAvailable = res.available
                self.usernameStatus = res.message
            }
        }
    }

    private func saveUserProfile() {
        repo.updateUserProfile(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            username: username.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: ""),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        )
        // Also claim username on Cloudflare Worker KV
        Task {
            _ = await CloudflareSyncService.claimUsername(
                username: username,
                uid: repo.userProfile.uid,
                email: email,
                displayName: displayName
            )
        }
        Haptics.success()
        withAnimation {
            saveSuccessMessage = "Profil başarıyla kaydedildi"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                saveSuccessMessage = nil
            }
        }
    }

    // MARK: - 2. Cloud & Device Sync Section
    private var cloudSyncSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("HESAP & BULUT SENKRONİZASYONU")

            // Status Row
            HStack {
                Text("Canlı Senkronizasyon Kanalı")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(mqtt.isConnected ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))
                        .frame(width: 8, height: 8)
                    Text(mqtt.isConnected ? "Çevrimiçi" : "Yerel Mod")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(mqtt.isConnected ? Color(hex: "#10B981") : AppTheme.textMuted(isDark: repo.isDarkMode))
                }
            }

            if let ts = mqtt.lastSyncTimestamp {
                HStack {
                    Text("Son Senkronizasyon")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    Spacer()
                    Text(ts, style: .time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                }
            }

            Divider().background(AppTheme.border(isDark: repo.isDarkMode))

            Text("Tüm cihazlarınızdaki projeleri anlık eşitlemek için ortak bir hesap e-postası girin.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                TextField("senkronizasyon@hesabi.com", text: $syncEmailInput)
                    .font(.system(size: 14))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
            }
            .padding(11)
            .background(AppTheme.card(isDark: repo.isDarkMode))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

            HStack(spacing: 10) {
                Button(action: {
                    let clean = syncEmailInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    mqtt.userEmail = clean
                    repo.userProfile.email = clean
                    repo.saveLocalDataDirect()
                    Haptics.success()
                    withAnimation {
                        syncStatusMessage = "Hesap bağlandı ve senkronize edildi"
                    }
                }) {
                    Text(mqtt.userEmail.isEmpty ? "Hesabı Eşle ve Bağlan" : "Hesabı Güncelle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.primary)
                        .cornerRadius(10)
                }
                .buttonStyle(.scaleSpring(scale: 0.97))

                if !mqtt.userEmail.isEmpty {
                    Button(action: {
                        mqtt.disconnect()
                        mqtt.userEmail = ""
                        syncEmailInput = ""
                        Haptics.medium()
                    }) {
                        Text("Çıkış Yap")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#EF4444"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#EF4444").opacity(0.12))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.scaleSpring(scale: 0.97))
                }
            }

            // Sync Now Button
            Button(action: {
                isSyncing = true
                Task {
                    await repo.syncWithCloud()
                    await MainActor.run {
                        self.isSyncing = false
                        self.syncStatusMessage = "Bulut senkronizasyonu tamamlandı"
                        Haptics.success()
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(isSyncing ? "Eşitleniyor..." : "Bulutla Şimdi Eşitle")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(repo.isDarkMode ? Color(hex: "#292524") : Color(hex: "#F1EFEB"))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }
            .buttonStyle(.scaleSpring(scale: 0.97))

            if let msg = syncStatusMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#10B981"))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    // MARK: - 3. AI API Pool Section
    private var aiPoolSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("YAPAY ZEKA (AI) API HAVUZU")

            Text("Yol haritası çıkarma, proje analizi ve akıllı asistan özellikleri için API anahtarlarınızı yapılandırın.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            // Preferred Model Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Varsayılan Yapay Zeka Modeli")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                Picker("Model", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { m in
                        Text(m).tag(m)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card(isDark: repo.isDarkMode))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
            }

            // Google Gemini API Key
            apiKeyInputRow(
                title: "Google Gemini API Key",
                placeholder: "AIzaSy...",
                key: $geminiKey,
                showKey: $showGeminiKey
            )

            // OpenAI API Key
            apiKeyInputRow(
                title: "OpenAI API Key",
                placeholder: "sk-proj-...",
                key: $openaiKey,
                showKey: $showOpenAiKey
            )

            // Anthropic Claude API Key
            apiKeyInputRow(
                title: "Anthropic Claude API Key",
                placeholder: "sk-ant-...",
                key: $claudeKey,
                showKey: $showClaudeKey
            )

            // DeepSeek API Key
            apiKeyInputRow(
                title: "DeepSeek API Key",
                placeholder: "sk-...",
                key: $deepseekKey,
                showKey: $showDeepseekKey
            )

            // Save Keys Button
            Button(action: saveApiKeys) {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13))
                    Text("API Anahtarlarını Kaydet")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppTheme.primary)
                .cornerRadius(10)
            }
            .buttonStyle(.scaleSpring(scale: 0.97))
        }
        .padding(16)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    private func apiKeyInputRow(
        title: String,
        placeholder: String,
        key: Binding<String>,
        showKey: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

            HStack {
                if showKey.wrappedValue {
                    TextField(placeholder, text: key)
                        .font(.system(size: 13, design: .monospaced))
                } else {
                    SecureField(placeholder, text: key)
                        .font(.system(size: 13, design: .monospaced))
                }

                Button(action: { showKey.wrappedValue.toggle() }) {
                    Image(systemName: showKey.wrappedValue ? "eye.slash" : "eye")
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .font(.system(size: 14))
                }
            }
            .padding(10)
            .background(AppTheme.card(isDark: repo.isDarkMode))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
        }
    }

    private func saveApiKeys() {
        repo.apiKeys = ApiKeysConfig(
            geminiApiKey: geminiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            openaiApiKey: openaiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            claudeApiKey: claudeKey.trimmingCharacters(in: .whitespacesAndNewlines),
            deepseekApiKey: deepseekKey.trimmingCharacters(in: .whitespacesAndNewlines),
            preferredModel: selectedModel
        )
        repo.saveLocalDataDirect()
        Haptics.success()
    }

    // MARK: - 4. Data Management & Reset Section
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("VERİ YÖNETİMİ & SIFIRLAMA")

            // Project Counts
            HStack {
                Text("Kayıtlı Proje Sayısı")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                Spacer()
                Text("\(repo.projects.count) (\(repo.activeProjects.count) aktif)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
            }

            Divider().background(AppTheme.border(isDark: repo.isDarkMode))

            // Reset Button
            Button(action: {
                showResetAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13))
                    Text("Tüm Verileri Sıfırla")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#EF4444"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color(hex: "#EF4444").opacity(0.12))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#EF4444").opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.scaleSpring(scale: 0.97))
        }
        .padding(16)
        .neumorphicCard(isDark: repo.isDarkMode)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
            .kerning(0.8)
    }
}
