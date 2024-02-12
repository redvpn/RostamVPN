// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class OnboardingPageViewController: UIViewController {
    let imageView = UIImageView()

    let label: UILabel = {
        let label = UILabel()
        let screenSize = UIScreen.main.bounds
        label.font = UIFont(name: "NunitoSans-Bold", size: screenSize.height < 600 ? 24.0 : 28.0)
        label.numberOfLines = 0
        label.textColor = UIColor.charcoalGrey
        return label
    }()

    init(image: String, title: String) {
        imageView.image = UIImage(named: image)
        label.text = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let screenSize = UIScreen.main.bounds

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: screenSize.height < 600 ? 56.0 : 76.0)
        ])

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: screenSize.height < 600 ? 35.0 : 55.0)
        ])
    }
}
