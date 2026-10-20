import SwiftUI

public struct ProfileView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var mqtt = MqttSyncEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var emailInput: String = ""
    @State private var geminiKey: String = ""
    @State private var openaiKey: String = ""
    @State private var selectedModel: String = "gemini-2.5-flash"

    private let availableModels = ["gemini-2.5-flash", "gemini-1.5-pro", "gpt-4o", "claude-3-5-sonnet"]

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // MARK: - Device Info Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                Text("Cihaz Kimliği")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                Spacer()
                                Text("iPhone 17 (SM-S936B Parity)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.primary)
                            }

                            Divider().background(AppTheme.border(isDark: repo.isDarkMode))

                            HStack {
                                Text("MQTT Senkronizasyonu")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(mqtt.isConnected ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                                        .frame(width: 8, height: 8)
                                    Text(mqtt.isConnected ? "HiveMQ Çevrimiçi" : "Yerel Mod")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                }
                            }

                            HStack {
                                Text("Eşzamanlı Cihazlar")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                Spacer()
                                Text("Galaxy S25+ & Tab S9 Ultra")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                            }
                        }
                        .padding(16)
                        .neumorphicCard(isDark: repo.isDarkMode)

                        // MARK: - Cross-Device Sync Setup
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ÇOKLU CİHAZ SENKRONİZASYON HESABI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            Text("Galaxy S25+ ve Tab S9 ile aynı e-posta adresini girerek projeleri anlık olarak eşitleyebilirsiniz.")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                                TextField("ornek@eposta.com", text: $emailInput)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(12)
                            .background(AppTheme.card(isDark: repo.isDarkMode))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))

                            Button(action: {
                                mqtt.userEmail = emailInput
                                Haptics.success()
                            }) {
                                Text("Hesabı Eşle ve Bağlan")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.primary)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .neumorphicCard(isDark: repo.isDarkMode)

                        // MARK: - AI API Keys Section (ProfileScreen.kt paritesi)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YAPAY ZEKA (AI) API ANAHTARLARI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            // Model Picker
                            Picker("Tercih Edilen Model", selection: $selectedModel) {
                                ForEach(availableModels, id: \.self) { m in
                                    Text(m).tag(m)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())

                            // Gemini Key
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Google Gemini API Key:")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                SecureField("AIzaSy...", text: $geminiKey)
                                    .font(.system(size: 13, design: .monospaced))
                                    .padding(10)
                                    .background(AppTheme.card(isDark: repo.isDarkMode))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                            }

                            // OpenAI Key
                            VStack(alignment: .leading, spacing: 4) {
                                Text("OpenAI API Key:")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                SecureField("sk-proj-...", text: $openaiKey)
                                    .font(.system(size: 13, design: .monospaced))
                                    .padding(10)
                                    .background(AppTheme.card(isDark: repo.isDarkMode))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border(isDark: repo.isDarkMode), lineWidth: 1))
                            }

                            Button(action: {
                                repo.apiKeys.geminiApiKey = geminiKey
                                repo.apiKeys.openaiApiKey = openaiKey
                                repo.apiKeys.preferredModel = selectedModel
                                repo.saveLocalData()
                                Haptics.success()
                            }) {
                                Text("API Anahtarlarını Kaydet")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.primary)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(16)
                        .neumorphicCard(isDark: repo.isDarkMode)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Profil ve Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
            .onAppear {
                self.emailInput = mqtt.userEmail
                self.geminiKey = repo.apiKeys.geminiApiKey
                self.openaiKey = repo.apiKeys.openaiApiKey
                self.selectedModel = repo.apiKeys.preferredModel
            }
        }
    }
}
