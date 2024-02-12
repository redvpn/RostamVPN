// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import PDFKit

class TermsAndConditionsViewController: UIViewController {
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont(name: "NunitoSans-Bold", size: 24.0)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor.charcoalGrey
        titleLabel.text = tr("termsAndConditionsTitle")
        return titleLabel
    }()

    let pdfView: PDFView = {
        let pdfView = PDFView()
        let urlPath = Bundle.main.path(forResource: "termsAndConditions", ofType: "pdf")
        let url = URL(fileURLWithPath: urlPath!)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.pageShadowsEnabled = false
        pdfView.document = PDFDocument(url: url)
        pdfView.backgroundColor = .white
        pdfView.pageBreakMargins = .zero
        return pdfView
    }()

    let acceptButton: UIButton = {
        let acceptButton = UIButton()
        acceptButton.layer.cornerRadius = 54 / 2
        acceptButton.clipsToBounds = true
        acceptButton.backgroundColor = UIColor.camel
        acceptButton.tintColor = UIColor.white
        acceptButton.titleLabel?.font = UIFont(name: "NunitoSans-Bold", size: 18.0)
        acceptButton.setTitle(tr("termsAndConditionsAccept"), for: .normal)
        return acceptButton
    }()

    var onAcceptButtonTouched: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let screenSize: CGRect = UIScreen.main.bounds

        let backgroundView = BackgroundShapeView(frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: view.frame.width, height: 120)))

        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)

        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 30.0)
        ])

        view.addSubview(acceptButton)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            acceptButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            acceptButton.heightAnchor.constraint(equalToConstant: 54.0),
            acceptButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: screenSize.height < 600 ? -20.0 : -40.0),
            acceptButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20.0),
            acceptButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20.0)
        ])

        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20.0),
            pdfView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20.0),
            pdfView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50.0),
            pdfView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: -50.0)
        ])

        acceptButton.addTarget(self, action: #selector(acceptButtonTouched), for: .touchUpInside)
    }

    @objc func acceptButtonTouched(_ sender: UIButton) {
        onAcceptButtonTouched?()
    }
}

