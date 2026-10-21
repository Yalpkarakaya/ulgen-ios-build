import Foundation

public class AiService {
    public static let shared = AiService()

    public func sendMessage(
        project: Project,
        userMessage: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let keys = ProjectRepository.shared.apiKeys

        // If Gemini API Key exists, call Gemini directly
        if !keys.geminiApiKey.isEmpty {
            callGemini(apiKey: keys.geminiApiKey, project: project, prompt: userMessage, completion: completion)
        } else if !keys.openaiApiKey.isEmpty {
            callOpenAI(apiKey: keys.openaiApiKey, project: project, prompt: userMessage, completion: completion)
        } else {
            // Local AI Simulation Engine (Çevrimdışı / API Anahtarsız Akıllı Yanıt)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let simulated = self.generateLocalExpertResponse(project: project, prompt: userMessage)
                completion(.success(simulated))
            }
        }
    }

    private func callGemini(apiKey: String, project: Project, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let model = ProjectRepository.shared.apiKeys.preferredModel.isEmpty ? "gemini-2.5-flash" : ProjectRepository.shared.apiKeys.preferredModel
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            completion(.failure(NSError(domain: "AiService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz API URL'i"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemInstruction = "Sen Ülgen Donanım ve Yazılım Mühendisliği Asistanısın. Kullanıcı projesi: '\(project.title)'. Açıklama: '\(project.description)'. Kategori: '\(project.category)'. Mühendislik standartlarına tam sadık, net, teknik, formül ve BOM odaklı yanıtlar üret. Asla emoji ve gereksiz övgü kullanma."

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "\(systemInstruction)\n\nKullanıcı Sorusu: \(prompt)"]
                    ]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let first = candidates.first,
                  let content = first["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                completion(.failure(NSError(domain: "AiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gemini yanıtı çözümlenemedi."])))
                return
            }

            DispatchQueue.main.async {
                completion(.success(text))
            }
        }.resume()
    }

    private func callOpenAI(apiKey: String, project: Project, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": "Ülgen Donanım Mühendisliği Asistanı. Net, teknik ve profesyonel ol."],
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let msg = first["message"] as? [String: Any],
                  let text = msg["content"] as? String else {
                completion(.failure(NSError(domain: "AiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "OpenAI yanıtı alınamadı."])))
                return
            }
            DispatchQueue.main.async { completion(.success(text)) }
        }.resume()
    }

    public func generateRoadmap(
        title: String,
        category: String,
        description: String,
        knownTopics: String = "",
        learningGoals: String = "",
        resources: String = "",
        objectives: [String] = [],
        aiPrompt: String = "",
        completion: @escaping (Result<[MainTopic], Error>) -> Void
    ) {
        let keys = ProjectRepository.shared.apiKeys

        if !keys.geminiApiKey.isEmpty {
            let model = keys.preferredModel.isEmpty ? "gemini-2.5-flash" : keys.preferredModel
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(keys.geminiApiKey)") else {
                completion(.success(buildStructuredFallbackRoadmap(title: title, category: category, description: description, knownTopics: knownTopics, learningGoals: learningGoals, resources: resources, objectives: objectives, aiPrompt: aiPrompt)))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let prompt = """
            Sen Ülgen Mühendislik Asistanısın. Proje için hiyerarşik bir yol haritası (MainTopic -> SubTopic -> Item) oluştur.
            Proje: \(title), Kategori: \(category), Açıklama: \(description)
            Yanıtını doğrudan JSON formatında [{\"title\":\"...\", \"description\":\"...\", \"subTopics\":[{\"title\":\"...\", \"description\":\"...\", \"items\":[{\"title\":\"...\"}]}]}] olarak ver.
            """

            let body: [String: Any] = [
                "contents": [["parts": [["text": prompt]]]]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let text = ((candidates.first?["content"] as? [String: Any])?["parts"] as? [[String: Any]])?.first?["text"] as? String,
                   let topics = self.parseRoadmapJson(text), !topics.isEmpty {
                    DispatchQueue.main.async { completion(.success(topics)) }
                } else {
                    DispatchQueue.main.async {
                        completion(.success(self.buildStructuredFallbackRoadmap(title: title, category: category, description: description, knownTopics: knownTopics, learningGoals: learningGoals, resources: resources, objectives: objectives, aiPrompt: aiPrompt)))
                    }
                }
            }.resume()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion(.success(self.buildStructuredFallbackRoadmap(title: title, category: category, description: description, knownTopics: knownTopics, learningGoals: learningGoals, resources: resources, objectives: objectives, aiPrompt: aiPrompt)))
            }
        }
    }

    public func buildStructuredFallbackRoadmap(
        title: String,
        category: String,
        description: String,
        knownTopics: String,
        learningGoals: String,
        resources: String,
        objectives: [String],
        aiPrompt: String
    ) -> [MainTopic] {
        let cleanTitle = title.isEmpty ? "Mühendislik Projesi" : title

        let topic1 = MainTopic(
            title: "1. Temel Gereksinimler & Mimari Analiz",
            description: "\(cleanTitle) kapsamında temel teknik gereksinimlerin ve sistem mimarisinin netleştirilmesi.",
            subTopics: [
                SubTopic(
                    title: "Şartname ve Standartların İncelenmesi",
                    description: "Toleranslar, elektriksel sınırlar ve hedef parametrelerin tespiti.",
                    estimatedHours: 2,
                    items: [
                        Item(title: "Hedef performans kriterlerinin ve toleransların belirlenmesi", order: 0),
                        Item(title: "Kullanılacak bileşen ve araç listesinin (BOM) netleştirilmesi", order: 1)
                    ],
                    order: 0
                ),
                SubTopic(
                    title: "Sistem Blok Şeması ve Akış",
                    description: "Giriş/çıkış arayüzleri ve sinyal akışının modellenmesi.",
                    estimatedHours: 3,
                    items: [
                        Item(title: "Ana fonksiyon blok diyagramının çizilmesi", order: 0),
                        Item(title: "Güç dağıtım ve haberleşme topolojisinin teyit edilmesi", order: 1)
                    ],
                    order: 1
                )
            ],
            order: 0
        )

        let topic2 = MainTopic(
            title: "2. Çekirdek Geliştirme & Entegrasyon",
            description: "Projenin ana yapı taşlarının ve donanım/yazılım katmanlarının hayata geçirilmesi.",
            subTopics: [
                SubTopic(
                    title: "Çekirdek Modüller ve Donanım/Yazılım Tasarımı",
                    description: "Şematik, PCB yerleşimi veya firmware çekirdek kodları.",
                    estimatedHours: 4,
                    items: [
                        Item(title: "Çekirdek şematik/kod yapısının oluşturulması", order: 0),
                        Item(title: "Simülasyon ve sanal analizlerin tamamlanması", order: 1)
                    ],
                    order: 0
                ),
                SubTopic(
                    title: "Prototipleme ve Modüler Doğrulama",
                    description: "Modüllerin masaüstü test ortamında adım adım doğrulanması.",
                    estimatedHours: 4,
                    items: [
                        Item(title: "Prototip donanım/yazılımın bir araya getirilmesi", order: 0),
                        Item(title: "Kritik sinyal ve gecikme parametrelerinin ölçülmesi", order: 1)
                    ],
                    order: 1
                )
            ],
            order: 1
        )

        let topic3 = MainTopic(
            title: "3. Doğrulama, Test & Nihai Teslim",
            description: "Nihai fonksiyonel testler, hata ayıklama ve projenin tamamlanması.",
            subTopics: [
                SubTopic(
                    title: "Kapsamlı Sistem Testleri ve İyileştirmeler",
                    description: "Sınır koşullarında çalışma ve dayanıklılık analizleri.",
                    estimatedHours: 3,
                    items: [
                        Item(title: "Farklı çalışma senaryolarında sistem davranışının doğrulanması", order: 0),
                        Item(title: "Gözlemlenen limit ve hataların giderilmesi", order: 1)
                    ],
                    order: 0
                ),
                SubTopic(
                    title: "Nihai Dokümantasyon ve Kalite Kontrol",
                    description: "Test raporlarının çıkarılması ve teslimat hazırlığı.",
                    estimatedHours: 2,
                    items: [
                        Item(title: "Teknik dokümantasyon ve ölçüm sonuçlarının arşivlenmesi", order: 0),
                        Item(title: "Kalite kontrol kontrol listesinin eksiksiz onaylanması", order: 1)
                    ],
                    order: 1
                )
            ],
            order: 2
        )

        return [topic1, topic2, topic3]
    }

    private func parseRoadmapJson(_ raw: String) -> [MainTopic]? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```json") { text = String(text.dropFirst(7)) }
        if text.hasPrefix("```") { text = String(text.dropFirst(3)) }
        if text.hasSuffix("```") { text = String(text.dropLast(3)) }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = text.data(using: .utf8),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }

        return list.enumerated().map { tIdx, tObj in
            let title = (tObj["title"] as? String) ?? "Aşama \(tIdx + 1)"
            let desc = (tObj["description"] as? String) ?? ""
            let subsJson = (tObj["subTopics"] as? [[String: Any]]) ?? []

            let subTopics: [SubTopic] = subsJson.enumerated().map { sIdx, sObj in
                let sTitle = (sObj["title"] as? String) ?? "Alt Aşama \(sIdx + 1)"
                let sDesc = (sObj["description"] as? String) ?? ""
                let itemsJson = (sObj["items"] as? [[String: Any]]) ?? []

                let items: [Item] = itemsJson.enumerated().map { iIdx, iObj in
                    let iTitle = (iObj["title"] as? String) ?? "Görev \(iIdx + 1)"
                    return Item(title: iTitle, order: iIdx)
                }

                return SubTopic(title: sTitle, description: sDesc, items: items, order: sIdx)
            }

            return MainTopic(title: title, description: desc, subTopics: subTopics, order: tIdx)
        }
    }

    private func generateLocalExpertResponse(project: Project, prompt: String) -> String {
        let pLower = prompt.lowercased()
        if pLower.contains("bom") || pLower.contains("malzeme") {
            return """
            ### Malzeme Listesi (BOM) Önerisi: \(project.title)
            1. **Ana Denetleyici:** STM32G474RET6 (LQFP-64, 170MHz, HRTIM)
            2. **Güç Yarıiletkeni:** GaN Systems / EPC GaN FET (100V, 15A)
            3. **Sürücü IC:** TI UCC27282 (120V Bootstrapped Half-Bridge Driver)
            4. **Pasifler:** 0402 1% ince film dirençler, X7R 50V seramik kapasitör dizisi
            5. **İndüktör:** Coilcraft XAL7030-222MEC (2.2µH, Isat: 18.5A)
            """
        } else if pLower.contains("görev") || pLower.contains("aşama") || pLower.contains("böl") {
            return """
            ### Önerilen Alt Çalışma Aşamaları:
            - [ ] **Şematik Kontrol:** HRTIM PWM çıkış hatlarına 10Ω sönümleme dirençlerinin eklenmesi.
            - [ ] **Termal Simülasyon:** 1MHz anahtarlama altında GaN FET RDS(on) sıcaklık artışının modellenmesi.
            - [ ] **Empedans Eşleme:** Gate sürücü loop alanının < 15mm² tutulması için PCB yerleşimi.
            - [ ] **Firmware Başlatma:** ADC senkron tetikleme ile akım okuma kalibrasyonu.
            """
        } else {
            return """
            **Analiz Raporu: \(project.title)**
            Mevcut ilerleme: %\(project.progress).
            Kritik yol: Sürücü gecikmesi ve dead-time dengesi kontrol edilmelidir.
            Öneri: Alt aşamalarda tanımlanan testleri sırayla tamamlayarak ilerleme yüzdesini güncelleyiniz.
            """
        }
    }
}
