import Foundation
import NaturalLanguage
import os
#if canImport(FoundationModels)
import FoundationModels
#endif

// Three free layers, best available wins:
//   1. Apple's on-device foundation model (iOS 26, Apple Intelligence hardware)
//   2. Extractive: top sentences by term-frequency score (every device)
//   3. Caller keeps the publisher og:description
// Main-app only — the share extension's memory ceiling is no place for an
// LLM; extension saves get upgraded on the app's next activation.
enum Summarizer {

    private static let log = Logger(subsystem: "com.mickeyoh.naru", category: "summarizer")

    static func summarize(url urlString: String) async -> String? {
        guard let text = await articleText(from: urlString), text.count >= 300 else {
            log.info("no usable article text for \(urlString, privacy: .public)")
            return nil
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            do {
                let session = LanguageModelSession(instructions:
                    "You summarize web page text in 2-3 plain sentences. " +
                    "Write in the same language as the content. Describe only what " +
                    "the page says — never mention 'the user', the request, or " +
                    "yourself, and never refuse; a thin or promotional page gets a " +
                    "one-sentence factual description. No preamble, no bullets.")
                let response = try await session.respond(to: String(text.prefix(8000)))
                let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if isUsable(summary) {
                    log.info("foundation-model summary for \(urlString, privacy: .public)")
                    return summary
                }
                log.info("model output rejected, falling back: \(summary.prefix(60), privacy: .public)")
            } catch {
                log.error("foundation model failed: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            log.info("foundation model unavailable, using extractive")
        }
        #endif

        if let extractive = extractiveSummary(of: text) {
            log.info("extractive summary for \(urlString, privacy: .public)")
            return extractive
        }
        return nil
    }

    // refusals and meta-commentary must never reach the archive
    private static func isUsable(_ summary: String) -> Bool {
        guard summary.count >= 40 else { return false }
        let lower = summary.lowercased()
        let poison = ["i'm sorry", "i am sorry", "i cannot", "i can't",
                      "the user is", "the user sent", "as an ai", "i'd be happy"]
        return !poison.contains { lower.contains($0) }
    }

    // MARK: - Article text

    private static func articleText(from urlString: String) async -> String? {
        let normalized = urlString.hasPrefix("http") ? urlString : "https://" + urlString
        guard let url = URL(string: normalized) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) else { return nil }

        var body = html
        for tag in ["script", "style", "noscript", "svg", "header", "footer", "nav", "form"] {
            body = body.replacingOccurrences(
                of: "<\(tag)[^>]*>[\\s\\S]*?</\(tag)>",
                with: " ", options: [.regularExpression, .caseInsensitive])
        }

        var paragraphs: [String] = []
        let pattern = try? NSRegularExpression(pattern: "<p[^>]*>([\\s\\S]*?)</p>", options: .caseInsensitive)
        pattern?.enumerateMatches(in: body, range: NSRange(body.startIndex..., in: body)) { match, _, _ in
            guard let match, let range = Range(match.range(at: 1), in: body) else { return }
            let stripped = decodeEntities(
                String(body[range])
                    .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression))
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if stripped.count >= 60 { paragraphs.append(stripped) }
        }
        let joined = paragraphs.joined(separator: "\n")
        return joined.isEmpty ? nil : joined
    }

    // MARK: - Extractive fallback

    private static func extractiveSummary(of text: String) -> String? {
        var sentences: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count >= 40, sentence.count <= 400 { sentences.append(sentence) }
            return true
        }
        guard sentences.count >= 3 else { return nil }

        var frequency: [String: Double] = [:]
        for sentence in sentences {
            for word in words(of: sentence) { frequency[word, default: 0] += 1 }
        }

        let scored = sentences.enumerated().map { index, sentence -> (Int, String, Double) in
            let tokens = words(of: sentence)
            guard !tokens.isEmpty else { return (index, sentence, 0) }
            let score = tokens.reduce(0) { $0 + (frequency[$1] ?? 0) } / Double(tokens.count).squareRoot()
            return (index, sentence, score)
        }

        let top = scored.sorted { $0.2 > $1.2 }.prefix(3).sorted { $0.0 < $1.0 }
        let summary = top.map(\.1).joined(separator: " ")
        return summary.isEmpty ? nil : summary
    }

    private static func decodeEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    private static func words(of sentence: String) -> [String] {
        sentence.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 }
    }
}
