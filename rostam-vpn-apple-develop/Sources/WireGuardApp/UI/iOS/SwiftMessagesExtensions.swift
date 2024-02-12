// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation
import UIKit
import SwiftMessages

enum MessageDuration: Int {
    case indefinite = -1
    case short = 3
    case medium = 5
    case long = 8
}

enum MessageType {
    case success, error, info
}

extension SwiftMessages {
    static let noInternetConnetionMessageId = "NO_INTERNET_CONNECTION"

    static func show(type: MessageType, message: String, duration: MessageDuration, id: String? = nil) {
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .bottom
        config.interactiveHide = true
        config.duration = duration == MessageDuration.indefinite ? .forever : .seconds(seconds: TimeInterval(duration.rawValue))

        let view = SnackbarView(message: message, icon: getIcon(type: type), id: id)
        view.backgroundColor = getBackgroundColor(type: type)

        SwiftMessages.show(config: config, view: view)
    }

    static func showConfigRequestMessage() {
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .bottom
        config.interactiveHide = false
        config.duration = .forever

        let view = ConfigRequestSnackbarView()

        SwiftMessages.show(config: config, view: view)
    }

    static func showDigitalSafetyMessage(title: String, shortDescription: String, link: String) {
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .bottom
        config.interactiveHide = true
        config.duration = .forever

        let view = DigitalSafetySnackbarView(title: title, shortDescription: shortDescription, link: link)

        SwiftMessages.show(config: config, view: view)
    }

    private static func getIcon(type: MessageType) -> String {
        switch type {
        case MessageType.success:
            return "iconSuccess"
        case MessageType.error:
            return "iconError"
        case MessageType.info:
            return "iconInfo"
        }
    }

    private static func getBackgroundColor(type: MessageType) -> UIColor {
        switch type {
        case MessageType.success:
            return UIColor.snackbarSuccess
        case MessageType.error:
            return UIColor.snackbarError
        case MessageType.info:
            return UIColor.snackbarInfo
        }
    }

}
