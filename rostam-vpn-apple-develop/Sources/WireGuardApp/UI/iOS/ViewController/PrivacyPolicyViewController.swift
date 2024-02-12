// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import PDFKit

class PrivacyPolicyViewController: SubpageViewController {
    let pdfView: PDFView = {
        let pdfView = PDFView()
        let urlPath = Bundle.main.path(forResource: "privacyPolicy", ofType: "pdf")
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

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20.0),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20.0)
        ])

        restorationIdentifier = "PrivacyPolicyVC"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Scroll to the top...
        if let pdfDocument = self.pdfView.document {
            if let firstPage = pdfDocument.page(at: 0) {
                if let selection = pdfDocument.selection(from: firstPage, atCharacterIndex: 0, to: firstPage, atCharacterIndex: 10) {
                    self.pdfView.go(to: selection)
                }
            }
        }

        self.pdfView.minScaleFactor = self.pdfView.scaleFactor
        self.pdfView.maxScaleFactor = self.pdfView.scaleFactor
    }
}
