import Foundation
import AVFoundation

// MARK: - Parsed Alarm from voice input

struct ParsedAlarm: Codable {
    var transcript: String
    var title: String
    var hour: Int
    var minute: Int
    var year: Int?       // e.g. 2026, nil if not mentioned
    var month: Int?      // 1-12, nil if not mentioned
    var day: Int?        // 1-31, nil if not mentioned
    var repeatDays: [Int] // Empty = one-time, 1=Sunday..7=Saturday
}

// MARK: - Gemini API Service

@Observable
final class GeminiService {
    static let apiKey: String = {
        guard let key = KeychainHelper.read(key: "GEMINI_API_KEY"), !key.isEmpty else {
            fatalError("GEMINI_API_KEY not found in Keychain. Ensure Secrets.plist is bundled for first launch.")
        }
        return key
    }()
    private static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    var isProcessing = false
    var errorMessage: String?

    /// Sends recorded audio (WAV) to Gemini and returns a ParsedAlarm with structured data.
    func processAudio(fileURL: URL) async -> ParsedAlarm? {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        // Read audio file and encode to base64
        guard let audioData = try? Data(contentsOf: fileURL) else {
            errorMessage = "Failed to read audio file."
            return nil
        }
        let base64Audio = audioData.base64EncodedString()

        // Build the request — include today's date so Gemini can resolve relative dates
        let now = Date()
        let cal = Calendar.current
        let todayYear = cal.component(.year, from: now)
        let todayMonth = cal.component(.month, from: now)
        let todayDay = cal.component(.day, from: now)

        let prompt = """
        You are a voice assistant for a reminder/alarm app. Today's date is \(todayYear)-\(String(format: "%02d", todayMonth))-\(String(format: "%02d", todayDay)).

        Listen to the audio and extract:
        1. "transcript" - the exact words the user said
        2. "title" - a short title for the reminder (e.g. "GYM", "Wake up", "Vaihitha's Birthday")
        3. "hour" - the hour in 24-hour format (0-23). If no time is mentioned, use 9 (9 AM as default).
        4. "minute" - the minute (0-59). If no time is mentioned, use 0.
        5. "year" - the year as integer (e.g. 2026). If a specific date is mentioned (like "Sept 24th"), determine the year. If the date has already passed this year, use next year. If no date is mentioned, use 0.
        6. "month" - month as integer 1-12. If a specific date/month is mentioned, extract it. If "tomorrow" is said, compute tomorrow's month. If no date is mentioned, use 0.
        7. "day" - day of month as integer 1-31. If a specific date is mentioned, extract it. If "tomorrow" is said, compute tomorrow's day. If no date is mentioned, use 0.
        8. "repeatDays" - array of weekday numbers where 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday. Use empty array [] for one-time. Use [1,2,3,4,5,6,7] for "daily" or "every day". Use [2,3,4,5,6] for "weekdays". Use [1,7] for "weekends".

        IMPORTANT: When user mentions a specific date (like "Sept 24th", "March 15", "tomorrow", "next Friday"), always extract year/month/day and use empty repeatDays []. When user says "daily"/"every day"/"weekdays" etc., use repeatDays and set year/month/day to 0.

        Examples:
        - "Remind me about Vaihitha's Birthday on Sept 24th" → {"transcript":"Remind me about Vaihitha's Birthday on Sept 24th","title":"Vaihitha's Birthday","hour":9,"minute":0,"year":2026,"month":9,"day":24,"repeatDays":[]}
        - "Remind me about GYM at 8PM daily" → {"transcript":"Remind me about GYM at 8PM daily","title":"GYM","hour":20,"minute":0,"year":0,"month":0,"day":0,"repeatDays":[1,2,3,4,5,6,7]}
        - "Wake me up at 7AM on weekdays" → {"transcript":"Wake me up at 7AM on weekdays","title":"Wake up","hour":7,"minute":0,"year":0,"month":0,"day":0,"repeatDays":[2,3,4,5,6]}
        - "Set alarm for 6:30 AM tomorrow" → {"transcript":"Set alarm for 6:30 AM tomorrow","title":"Alarm","hour":6,"minute":30,"year":\(todayYear),"month":\(todayMonth),"day":\(todayDay + 1),"repeatDays":[]}
        - "Meeting on March 15 at 2PM" → {"transcript":"Meeting on March 15 at 2PM","title":"Meeting","hour":14,"minute":0,"year":2027,"month":3,"day":15,"repeatDays":[]}
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inlineData": [
                                "mimeType": "audio/wav",
                                "data": base64Audio
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseJsonSchema": [
                    "type": "object",
                    "properties": [
                        "transcript": ["type": "string", "description": "Exact words the user said"],
                        "title": ["type": "string", "description": "Short reminder title extracted from speech"],
                        "hour": ["type": "integer", "description": "Hour in 24-hour format (0-23). Default 9 if not mentioned."],
                        "minute": ["type": "integer", "description": "Minute (0-59). Default 0 if not mentioned."],
                        "year": ["type": "integer", "description": "Year (e.g. 2026). 0 if no specific date mentioned."],
                        "month": ["type": "integer", "description": "Month 1-12. 0 if no specific date mentioned."],
                        "day": ["type": "integer", "description": "Day of month 1-31. 0 if no specific date mentioned."],
                        "repeatDays": [
                            "type": "array",
                            "items": ["type": "integer"],
                            "description": "Weekday numbers: 1=Sun,2=Mon,3=Tue,4=Wed,5=Thu,6=Fri,7=Sat. Empty for one-time."
                        ]
                    ],
                    "required": ["transcript", "title", "hour", "minute", "year", "month", "day", "repeatDays"]
                ] as [String: Any]
            ] as [String: Any]
        ]

        guard let url = URL(string: "\(GeminiService.endpoint)?key=\(GeminiService.apiKey)") else {
            errorMessage = "Invalid API URL."
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "Failed to build request: \(error.localizedDescription)"
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response from server."
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? "No body"
                errorMessage = "API error (\(httpResponse.statusCode)): \(body)"
                print("Gemini API error: \(body)")
                return nil
            }

            // Parse the Gemini response envelope
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                errorMessage = "Failed to parse API response."
                return nil
            }

            // The text should be valid JSON matching our schema
            guard let jsonData = text.data(using: .utf8) else {
                errorMessage = "Invalid response text encoding."
                return nil
            }

            let parsed = try JSONDecoder().decode(ParsedAlarm.self, from: jsonData)
            return parsed

        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            return nil
        }
    }

    /// Transcribes audio to text only (for Quick Stuff / notes mode).
    func transcribeAudio(fileURL: URL) async -> String? {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        guard let audioData = try? Data(contentsOf: fileURL) else {
            errorMessage = "Failed to read audio file."
            return nil
        }
        let base64Audio = audioData.base64EncodedString()

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Transcribe the following audio exactly as spoken. Return only the transcribed text, nothing else."],
                        [
                            "inlineData": [
                                "mimeType": "audio/wav",
                                "data": base64Audio
                            ]
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "\(GeminiService.endpoint)?key=\(GeminiService.apiKey)") else {
            errorMessage = "Invalid API URL."
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "Failed to build request: \(error.localizedDescription)"
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? "No body"
                errorMessage = "API error: \(body)"
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                errorMessage = "Failed to parse API response."
                return nil
            }

            return text.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            return nil
        }
    }
}
