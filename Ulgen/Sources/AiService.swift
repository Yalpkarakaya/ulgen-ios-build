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
