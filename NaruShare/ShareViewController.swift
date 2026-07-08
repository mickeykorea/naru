import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let host = UIHostingController(rootView: ShareSaveView(
            loadURL: { [weak self] in await self?.incomingURL() },
            finish: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            cancel: { [weak self] in
                self?.extensionContext?.cancelRequest(
                    withError: NSError(domain: "com.mickeyoh.naru.share",
                                       code: NSUserCancelledError))
            }
        ))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .systemBackground
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func incomingURL() async -> URL? {
        let providers = (extensionContext?.inputItems ?? [])
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = await load(UTType.url, from: provider) as? URL,
               url.scheme?.hasPrefix("http") == true {
                return url
            }
        }
        // some apps share the link inside plain text
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = await load(UTType.plainText, from: provider) as? String,
               let url = Self.firstLink(in: text) {
                return url
            }
        }
        return nil
    }

    private func load(_ type: UTType, from provider: NSItemProvider) async -> (any NSSecureCoding)? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    private static func firstLink(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        return detector?.firstMatch(in: text, range: range)?.url
    }
}
