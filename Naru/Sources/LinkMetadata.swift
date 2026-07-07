import LinkPresentation
import UIKit

struct LinkPreview {
    var title: String?
    var image: UIImage?
    var summary: String?
}

enum LinkMetadataFetcher {

    static func fetch(_ urlString: String) async -> LinkPreview {
        guard let url = URL(string: urlString.hasPrefix("http") ? urlString : "https://" + urlString) else {
            return LinkPreview()
        }
        var preview = await fetchViaLinkPresentation(url)
        // LinkPresentation never surfaces descriptions; the HTML pass fills
        // summary and any other gaps
        if preview.title == nil || preview.image == nil || preview.summary == nil {
            let fallback = await fetchViaHTML(url)
            preview.title = preview.title ?? fallback.title
            preview.image = preview.image ?? fallback.image
            preview.summary = preview.summary ?? fallback.summary
        }
        return preview
    }

    private static func fetchViaLinkPresentation(_ url: URL) async -> LinkPreview {
        await withCheckedContinuation { continuation in
            let provider = LPMetadataProvider()
            provider.timeout = 8
            provider.startFetchingMetadata(for: url) { metadata, _ in
                guard let metadata else {
                    continuation.resume(returning: LinkPreview())
                    return
                }
                let title = metadata.title
                guard let imageProvider = metadata.imageProvider else {
                    continuation.resume(returning: LinkPreview(title: title))
                    return
                }
                imageProvider.loadObject(ofClass: UIImage.self) { image, _ in
                    continuation.resume(returning: LinkPreview(title: title, image: image as? UIImage))
                }
            }
        }
    }

    private static func fetchViaHTML(_ url: URL) async -> LinkPreview {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return LinkPreview()
        }

        let title = firstMatch(in: html, patterns: [
            #"<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']"#,
            #"<title[^>]*>([^<]+)</title>"#,
        ]).map(decodeHTMLEntities)

        let summary = firstMatch(in: html, patterns: [
            #"<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:description["']"#,
            #"<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']description["']"#,
        ]).map(decodeHTMLEntities)

        var image: UIImage?
        if let imageURLString = firstMatch(in: html, patterns: [
            #"<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']"#,
        ]), let imageURL = URL(string: imageURLString, relativeTo: url),
           let (imageData, _) = try? await URLSession.shared.data(from: imageURL) {
            image = UIImage(data: imageData)
        }

        return LinkPreview(title: title, image: image, summary: summary)
    }

    private static func firstMatch(in html: String, patterns: [String]) -> String? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: html) {
                let value = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { return value }
            }
        }
        return nil
    }

    private static func decodeHTMLEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
