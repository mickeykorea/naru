import Foundation

// App-only: Summarizer (and the on-device model) never runs inside the
// share extension — extension saves keep the publisher description and
// get upgraded here on the app's next activation.
extension ArchiveStore {

    func upgradeSummaries() async {
        guard !upgradingSummaries else { return }
        upgradingSummaries = true
        defer { upgradingSummaries = false }

        while let target = items.first(where: { $0.summaryUpgraded != true }) {
            let summary = await Summarizer.summarize(url: target.url)
            mutate { items in
                guard let index = items.firstIndex(where: { $0.id == target.id }) else { return }
                if let summary, !summary.isEmpty {
                    items[index].summary = summary
                }
                items[index].summaryUpgraded = true
            }
            // safety valve: if the mutate above could not find the item,
            // ensure we never loop on the same target forever
            if items.first(where: { $0.summaryUpgraded != true })?.id == target.id { break }
        }
    }
}
