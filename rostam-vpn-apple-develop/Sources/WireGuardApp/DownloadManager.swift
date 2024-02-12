// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation

class DownloadManager {
    var fileManager: FileManager

    init() {
        self.fileManager = FileManager.default
    }

    func downloadFile(url: URL, saveAs destination: URL, completion: @escaping (Bool) -> Void) {
        if fileManager.fileExists(atPath: destination.path) {
            if fileManager.isDeletableFile(atPath: destination.path) {
                do {
                    try fileManager.removeItem(at: destination)
                    self.saveFile(url: url, destination: destination) { response in
                        completion(response)
                    }
                } catch let error {
                    debugPrint("\(error)")
                }
            }
        } else {
            self.saveFile(url: url, destination: destination) { response in
                completion(response)
            }
        }
    }

    private func saveFile(url: URL, destination: URL, completionHandler: @escaping (Bool) -> Void) {
        let urlSession = URLSession.shared
        let task = urlSession.downloadTask(with: url) { location, response, error in
            if let error = error {
                debugPrint(error)
            } else if let location = location, let response = response as? HTTPURLResponse,
            response.statusCode == 200 {
                do {
                    try self.fileManager.moveItem(at: location, to: destination)
                    debugPrint("File downloaded successfully.")
                    completionHandler(true)
                } catch {
                    debugPrint("Could not save the file: \(error)")
                    completionHandler(false)
                }
            }
        }

        task.resume()
    }
}
