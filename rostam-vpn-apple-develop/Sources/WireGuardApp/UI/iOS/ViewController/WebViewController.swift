// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    private var landingPageUrl = "https://www.rostam.app/ads/01/"
    var ip = ""
    var webView: WKWebView!
    var counter = 5

    let countdownLabel: UILabel = {
        let countdownLabel = UILabel()
        countdownLabel.font = UIFont(name: "NunitoSans-Regular", size: 20.0)
        countdownLabel.textColor = UIColor.charcoalGrey
        countdownLabel.text = "5"
        countdownLabel.isHidden = true
        return countdownLabel
    }()

    let closeIcon: UIImageView = {
        let closeIcon = UIImageView()
        closeIcon.image = UIImage(named: "iconClose")!.withRenderingMode(.alwaysTemplate)
        closeIcon.tintColor = UIColor.charcoalGrey
        closeIcon.isUserInteractionEnabled = true
        closeIcon.isHidden = true
        return closeIcon
    }()

    convenience init(ip: String?) {
        self.init()
        self.ip = ip!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(countdownLabel)
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countdownLabel.widthAnchor.constraint(equalToConstant: 24.0),
            countdownLabel.heightAnchor.constraint(equalToConstant: 24.0),
            countdownLabel.leftAnchor.constraint(equalTo: view.safeLeftAnchor, constant: 10.0),
            countdownLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 30.0)
        ])

        view.addSubview(closeIcon)
        closeIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeIcon.widthAnchor.constraint(equalToConstant: 24.0),
            closeIcon.heightAnchor.constraint(equalToConstant: 24.0),
            closeIcon.leftAnchor.constraint(equalTo: view.safeLeftAnchor, constant: 20.0),
            closeIcon.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 30.0)
        ])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeIconTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        closeIcon.addGestureRecognizer(tapGestureRecognizer)

        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        webView = WKWebView(frame: view.bounds, configuration: configuration)

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            webView.topAnchor.constraint(equalTo: closeIcon.bottomAnchor, constant: 10.0),
            webView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        let url = URL(string: "\(landingPageUrl)?ip=\(ip)")
        let request = URLRequest(url: url!)
        webView.navigationDelegate = self
        webView.load(request)
    }

    @objc func closeIconTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
        self.countdownLabel.isHidden = false
    }

    @objc func updateCounter() {
        if counter > 0 {
            counter -= 1
            self.countdownLabel.text = "\(counter)"
        } else {
            self.countdownLabel.isHidden = true
            self.closeIcon.isHidden = false
        }
    }
}
