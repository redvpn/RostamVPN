// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class SubpageViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let navigationBar = navigationController!.navigationBar
        navigationBar.shadowImage = UIImage()
        navigationBar.barTintColor = .primaryDark
        navigationBar.isTranslucent = false
        navigationBar.tintColor = .white

        if #available(iOS 13.0, *) {
            let standardAppearance = navigationBar.standardAppearance.copy()

            let titleTextAttributes = [
                NSAttributedString.Key.font: UIFont(name: "NunitoSans-Bold", size: 20.0)!,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]

            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = .primaryDark
            standardAppearance.shadowColor = nil
            standardAppearance.buttonAppearance.normal.titleTextAttributes = titleTextAttributes

            navigationBar.standardAppearance = standardAppearance
            navigationBar.scrollEdgeAppearance = standardAppearance
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        let navigationBar = navigationController!.navigationBar
        navigationBar.shadowImage = UIImage()
        navigationBar.barTintColor = .white
        navigationBar.isTranslucent = false
        navigationBar.tintColor = .primaryDark

        if #available(iOS 13.0, *) {
            let standardAppearance = navigationBar.standardAppearance.copy()

            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = .white
            standardAppearance.shadowColor = nil

            navigationBar.standardAppearance = standardAppearance
            navigationBar.scrollEdgeAppearance = standardAppearance
        }
    }
}
