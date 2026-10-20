import SwiftUI

public struct ProfileView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var mqtt = MqttSyncEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var emailInput: String = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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
                                Text("iPhone 17")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.primary)
                            }

                            Divider().background(AppTheme.border(isDark: repo.isDarkMode))

                            HStack {
                                Text("Ağ Durumu")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(mqtt.isConnected ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                                        .frame(width: 8, height: 8)
                                    Text(mqtt.isConnected ? "MQTT Çevrimiçi (HiveMQ)" : "Yerel Mod")
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

                        // MARK: - Statistics Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("İSTATİSTİKLER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            HStack {
                                statBox(title: "Toplam Proje", value: "\(repo.projects.count)")
                                statBox(title: "Aktif", value: "\(repo.projects.filter { !$0.archived }.count)")
                                statBox(title: "Ortalama", value: "%" + String(repo.projects.isEmpty ? 0 : repo.projects.reduce(0) { $0 + $1.progress } / repo.projects.count))
                            }
                        }
                        .padding(16)
                        .neumorphicCard(isDark: repo.isDarkMode)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Profil ve Eşitleme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
            .onAppear {
                self.emailInput = mqtt.userEmail
            }
        }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.primary)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(repo.isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
        .cornerRadius(8)
    }
}
