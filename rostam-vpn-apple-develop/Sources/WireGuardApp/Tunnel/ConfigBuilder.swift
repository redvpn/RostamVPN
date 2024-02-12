// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import Foundation
import Amplitude

class ConfigBuilder {
    private static let apiDataKey = "rostamApiData"
    private static let apiExpiryKey = "rostamApiExpiry"
    private static var path = ""
//    private static var host = ""
    private static var domainFront = ""
    private static var apiUrl = "https://docs.google.com/feeds/download/documents/export/Export?id=1eU2garmd4ZKLCEGDoqpQ8I2-C7llC8u1chJ3uo1OPt8&exportFormat=html"

    private static var expiry = 0

    static func build(privateKey: PrivateKey, publicKey: PublicKey, region: String?, completionHandler: @escaping ((String?) -> Void)) {
        getApiData { success, error in
            if success {
                getProfileData(publicKey: publicKey, region: region) { apiResponse, errorMessage in
                    if let apiResponse = apiResponse {
                        let endpoint: String = apiResponse.endpoints[0]
                        let wgQuickConfig = createWqQuickConfig(privateKey: privateKey.base64Key, publicKey: apiResponse.publicKey, address: apiResponse.address, endpoint: endpoint)

                        Amplitude.instance().logEvent("Call to profile API succeeded")
                        completionHandler(wgQuickConfig)
                    } else {
                        if let errorMessage = errorMessage {
                            if !errorMessage.isEmpty {
                                let eventProperties = ["error": errorMessage as Any]
                                Amplitude.instance().logEvent("Call to profile API error", withEventProperties: eventProperties)
                            }
                        }

                        Amplitude.instance().logEvent("Call to profile API failed")
                        completionHandler(nil)
                    }
                }
            } else {
                if let error = error, !error.isEmpty {
                    let eventProperties = ["error": error as Any]
                    Amplitude.instance().logEvent("Failed to obtain API data JSON", withEventProperties: eventProperties)
                } else {
                    Amplitude.instance().logEvent("Failed to obtain API data JSON")
                }
                completionHandler(nil)
            }
        }
    }

    static func parse(privateKey: PrivateKey, pubkey: PublicKey, fileContents: String) -> String? {
        let jsonString = "\(fileContents.replacingOccurrences(of: "'", with: "\""))"
        let data = jsonString.data(using: .utf8)!
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        debugPrint(json)

        if let address = json["address"] as? String,
           let endpoints = json["endpoint"] as? [String],
           let clientPublicKey = json["client_pubkey"] as? String,
           let serverPublicKey = json["pubkey"] as? String {
            if clientPublicKey == pubkey.base64Key {
                EndpointManager.storeEndpoints(endpoints: endpoints, region: nil)

                let endpoint: String = endpoints[0]
                let wgQuickConfig = createWqQuickConfig(privateKey: privateKey.base64Key, publicKey: serverPublicKey, address: address, endpoint: endpoint)

                return wgQuickConfig
            }
        }

        return nil
    }

    private static func getProfileData(publicKey: PublicKey, region: String?, completionHandler: @escaping (ApiResponse?, String?) -> Void) {
        let profileApiUrl = "https://" + domainFront + path

        var request = URLRequest(url: URL(string: profileApiUrl)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
//        request.addValue(host, forHTTPHeaderField: "Host")
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        var parameterDictionary = ["pubkey": publicKey.base64Key]
        if let region = region {
            parameterDictionary["region"] = region
        }
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            completionHandler(nil, "JSON serialization error")
            return
        }
        request.httpBody = httpBody

        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request) { data, response, error -> Void in
            var errorMessage = ""
            if let error = error {
                debugPrint(error)
                errorMessage = error.localizedDescription
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                debugPrint(response)
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                    debugPrint(json)

                    if let status = json["status"] as? String,
                        status == "ok",
                        let message = json["message"] as? String,
                        let address = json["address"] as? String,
                        let endpoints = json["endpoint"] as? [String], let serverPublicKey = json["pubkey"] as? String {

                        EndpointManager.storeEndpoints(endpoints: endpoints, region: region)
                        let apiResponse = ApiResponse(status: status, message: message, address: address, endpoints: endpoints, publicKey: serverPublicKey)
                        completionHandler(apiResponse, nil)
                        return
                    } else if let message = json["message"] as? String {
                        debugPrint(message)
                        errorMessage = message
                    }
                } catch let error {
                    debugPrint(error)
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = "Invalid URL"
            }

            completionHandler(nil, errorMessage)
        }

        task.resume()
    }

    private static func getApiData(completionHandler: @escaping (Bool, String?) -> Void) {
        if !isExpired() {
            if let jsonString = UserDefaults.standard.value(forKey: apiDataKey) as? String {
                do {
                    try parseApiDataJson(jsonString: jsonString)

                    completionHandler(true, nil)
                    return
                } catch let error {
                    debugPrint(error)
                }
            }
        }

        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request) { _, response, error -> Void in
            var errorMessage = ""
            if let error = error {
                debugPrint(error)
                errorMessage = error.localizedDescription
            } else if let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let filename = response.suggestedFilename {

                let base64String: String = filename.components(separatedBy: ".")[0]
                if let data = Data(base64Encoded: base64String),
                   let jsonString = String(data: data, encoding: .utf8) {

                    do {
                        try parseApiDataJson(jsonString: jsonString)
                        storeExpiry(expiry: expiry)
                        storeApiData(jsonString: jsonString)

                        completionHandler(true, nil)
                        return
                    } catch let error {
                        debugPrint(error)
                        errorMessage = error.localizedDescription
                    }
                }

            }

            completionHandler(false, errorMessage)
        }

        task.resume()
    }

    private static func createWqQuickConfig(privateKey: String, publicKey: String, address: String, endpoint: String) -> String {
        var wgQuickConfig = "[Interface]\n"
        wgQuickConfig.append("PrivateKey = \(privateKey)\n")
        wgQuickConfig.append("Address = \(address)\n")
        wgQuickConfig.append("DNS = 8.8.8.8\n")
        wgQuickConfig.append("\n[Peer]\n")
        wgQuickConfig.append("PublicKey = \(publicKey)\n")
        wgQuickConfig.append("AllowedIPs = 0.0.0.0/0\n")
        wgQuickConfig.append("Endpoint = \(endpoint)\n")
        wgQuickConfig.append("PersistentKeepalive = 25")

        return wgQuickConfig
    }

    private static func storeApiData(jsonString: String) {
        UserDefaults.standard.set(jsonString, forKey: apiDataKey)
    }

    private static func storeExpiry(expiry: Int) {
        let calendar = Calendar.current
        let expiryDate = calendar.date(byAdding: .second, value: expiry, to: Date())
        UserDefaults.standard.set(expiryDate, forKey: apiExpiryKey)
    }

    private static func isExpired() -> Bool {
        if let expiryDate = UserDefaults.standard.value(forKey: apiExpiryKey) as? Date {
            let isExpired = Date() > expiryDate

            return isExpired
        }

        return true
    }

    private static func parseApiDataJson(jsonString: String) throws {
        if let jsonData = jsonString.data(using: .utf8) {
            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                let path = json["path"] as? String,
//                let host = json["host"] as? String,
                let domainFront = json["domain_front"] as? String,
                let apiUrl = json["apiURL"] as? String,
                let expiry = json["expiry"] as? Int {

                self.path = path
//                self.host = host
                self.domainFront = domainFront
                self.apiUrl = apiUrl
                self.expiry = expiry

                Amplitude.instance().logEvent("Successfully obtained API data JSON", withEventProperties: json)
                return
            }
        }

        Amplitude.instance().logEvent("Failed to parse API data JSON")
    }
}

struct ApiResponse {
    private(set) var status: String
    private(set) var message: String
    private(set) var address: String
    private(set) var endpoints: [String]
    private(set) var publicKey: String

    init(status: String, message: String, address: String, endpoints: [String], publicKey: String) {
        self.status = status
        self.message = message
        self.address = address
        self.endpoints = endpoints
        self.publicKey = publicKey
    }
}
