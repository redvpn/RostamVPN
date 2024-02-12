// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation
import SwiftCSV

class DigitalSafetyTips {
    private var digitalSafetyTipsIndex = "digitalSafetyTipsIndex"
    private var digitalSafetyTipsLastUpdate = "digitalSafetyTipsLastUpdate"
    private var csvUrl = "https://api.rostam.app/tips/Rostam-tips.csv"
    private var digitalSafetyTips: [DigitalSafetyTip]
    private var nextTipIndex = 0
    private var downloadManager: DownloadManager

    init() {
        digitalSafetyTips = [DigitalSafetyTip]()
        downloadManager = DownloadManager()
        nextTipIndex = getNextTipIndex()

        load()
    }

    func downloadData() {
        let lastUpdateDate = getLastUpdateDate()
        let now = Date()
        let diff = Int(now.timeIntervalSince(lastUpdateDate) / 3600)

        if diff >= 24 {
            guard let downloadUrl = URL(string: csvUrl), let localUrl = getLocalUrl() else { return }
            downloadManager.downloadFile(url: downloadUrl, saveAs: localUrl) { response in
                if response {
                    debugPrint("CSV download completed.")
                    self.setLastUpdateDate()
                    self.load()
                }
            }
        }
    }

    private func getLocalUrl() -> URL? {
        guard let libraryUrl = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        let csvUrl = libraryUrl.appendingPathComponent("digitalSafetyTips.csv")

        return csvUrl
    }

    func isEmpty() -> Bool {
        return self.digitalSafetyTips.isEmpty
    }

    func getNextTip() -> DigitalSafetyTip? {
        var nextTip: DigitalSafetyTip?
        if !self.digitalSafetyTips.isEmpty {
            if self.nextTipIndex > 0 {
                nextTip = digitalSafetyTips[self.nextTipIndex % self.digitalSafetyTips.count]
            }

            self.nextTipIndex += 1
            setNextTipIndex(nextTipIndex: nextTipIndex)
        }

        return nextTip
    }

    func load() {
            guard let url = getLocalUrl(), FileManager.default.fileExists(atPath: url.path) else {
                return
            }

            do {
                let csv = try CSV<Named>(url: url)

                try csv.enumerateAsDict { dict in
                    let title = dict["Title"] ?? ""
                    let shortDescription = dict["ShortDescription"] ?? ""
                    let urlString = dict["Url"] ?? ""

                    if !title.isEmpty && !shortDescription.isEmpty && urlString.isValidUrl {
                        let digitalSafetyTip = DigitalSafetyTip(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            shortDescription: shortDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                            url: urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        self.digitalSafetyTips.append(digitalSafetyTip)
                    }
                }
            } catch let error {
                debugPrint("Could not load the CSV file. Error: \(error.localizedDescription)")
            }
        }

    private func getNextTipIndex() -> Int {
        let value = UserDefaults.standard.value(forKey: self.digitalSafetyTipsIndex)

        return (value as? Int) ?? 0
    }

    private func setNextTipIndex(nextTipIndex: Int) {
        UserDefaults.standard.set(nextTipIndex, forKey: self.digitalSafetyTipsIndex)
    }

    private func getLastUpdateDate() -> Date {
        let value = UserDefaults.standard.value(forKey: self.digitalSafetyTipsLastUpdate)

        return (value as? Date) ?? Date.distantPast
    }

    private func setLastUpdateDate() {
        UserDefaults.standard.set(Date(), forKey: self.digitalSafetyTipsLastUpdate)
    }
}

class DigitalSafetyTip {
    let title: String
    let shortDescription: String
    let url: String

    init(title: String, shortDescription: String, url: String) {
        self.title = title
        self.shortDescription = shortDescription
        self.url = url
    }
}

extension String {
    var isValidUrl: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

            let stringUrl = self.trimmingCharacters(in: .whitespacesAndNewlines)
            if let match = detector.firstMatch(in: stringUrl, options: [], range: NSRange(location: 0, length: stringUrl.utf16.count)) {

                return match.range.length == stringUrl.utf16.count
            } else {
                return false
            }
        } catch {
            return false
        }
    }
}

