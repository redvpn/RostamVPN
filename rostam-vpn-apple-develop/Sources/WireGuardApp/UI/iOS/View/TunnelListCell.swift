// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import Connectivity
import SwiftMessages

class TunnelListCell: UITableViewCell, NetworkStatusListener {
    var tunnel: TunnelContainer? {
        didSet(value) {
            // Bind to the tunnel's status
            update(from: tunnel?.rostamStatus)
            statusObservationToken = tunnel?.observe(\.status) { [weak self] tunnel, _ in
                self?.update(from: tunnel.rostamStatus)
            }
            checkingConnectivityObservationToken = tunnel?.observe(\.isCheckingConnectivity) { [weak self] tunnel, _ in
                self?.update(from: tunnel.rostamStatus)
            }
            gettingNewEndpointsObservationToken = tunnel?.observe(\.isGettingNewEndpoints) { [weak self] tunnel, _ in
                self?.update(from: tunnel.rostamStatus)
            }
        }
    }
    var onImageTapped: (() -> Void)?

    let busyIndicator: UIActivityIndicatorView = {
        let busyIndicator = UIActivityIndicatorView(style: .whiteLarge)
        busyIndicator.hidesWhenStopped = true
        busyIndicator.color = UIColor.accent
        return busyIndicator
    }()

    let rostamImageView: UIImageView = {
        let rostamImageView = UIImageView()
        rostamImageView.image = UIImage(named: "rostamInactive")
        return rostamImageView
    }()

    let stateLabel: UILabel = {
        let stateLabel = UILabel()
        stateLabel.font = UIFont(name: "NunitoSans-Bold", size: 24.0)
        stateLabel.numberOfLines = 0
        stateLabel.textColor = UIColor.charcoalGrey
        stateLabel.text = tr("vpnStateOff")
        return stateLabel
    }()

    let infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        infoLabel.numberOfLines = 0
        infoLabel.textColor = UIColor.charcoalGrey
        infoLabel.text = tr("tapToConnect")
        infoLabel.textAlignment = NSTextAlignment.center
        return infoLabel
    }()

    private var statusObservationToken: AnyObject?
    private var checkingConnectivityObservationToken: AnyObject?
    private var gettingNewEndpointsObservationToken: AnyObject?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let screenSize: CGRect = UIScreen.main.bounds

        contentView.addSubview(rostamImageView)
        rostamImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rostamImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rostamImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            rostamImageView.widthAnchor.constraint(equalToConstant: CGFloat(screenSize.height < 600 ? 125 : 190)),
            rostamImageView.heightAnchor.constraint(equalToConstant: CGFloat(screenSize.height < 600 ? 200 : 300))
        ])

        contentView.addSubview(busyIndicator)
        busyIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            busyIndicator.centerXAnchor.constraint(equalTo: rostamImageView.centerXAnchor),
            busyIndicator.centerYAnchor.constraint(equalTo: rostamImageView.centerYAnchor)
        ])

        contentView.addSubview(stateLabel)
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stateLabel.topAnchor.constraint(equalTo: rostamImageView.bottomAnchor, constant: 20),
            stateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])

        contentView.addSubview(infoLabel)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 16),
            infoLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            infoLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            infoLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
        ])

        rostamImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        rostamImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func imageTapped() {
        onImageTapped?()
    }

    private func update(from status: TunnelStatus?) {
        guard let status = status else {
            reset()
            return
        }
        DispatchQueue.main.async { [weak rostamImageView, weak busyIndicator, weak stateLabel, weak infoLabel] in
            guard let rostamImageView = rostamImageView, let busyIndicator = busyIndicator, let stateLabel = stateLabel, let infoLabel = infoLabel else { return }
            if status == .active && ConnectivityManager.shared.isNetworkAvailable {
                rostamImageView.image = UIImage(named: "rostamActive")
                let text = tr("vpnStateOn")
                let textToColor = tr("on")
                let range = (text as NSString).range(of: textToColor)
                let attributedText = NSMutableAttributedString(string: text)
                attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.jadeGreen, range: range)
                stateLabel.attributedText = attributedText
                infoLabel.text = tr("tapToDisconnect")
            } else {
                rostamImageView.image = UIImage(named: "rostamInactive")
                stateLabel.text = status == .activating ? tr("vpnStateConnecting") : tr("vpnStateOff")
                infoLabel.text = status == .activating ? tr("connecting") : tr("tapToConnect")
            }
            rostamImageView.isUserInteractionEnabled = (status == .inactive || status == .active) && ConnectivityManager.shared.isNetworkAvailable
            if status == .activating || status == .deactivating {
                busyIndicator.startAnimating()
            } else {
                busyIndicator.stopAnimating()
            }
        }
    }

    func networkStatusDidChange(status: ConnectivityStatus) {
        if ConnectivityManager.shared.isNetworkAvailable == false {
            update(from: TunnelStatus.inactive)
            if SwiftMessages.current(id: SwiftMessages.noInternetConnetionMessageId) == nil {
                SwiftMessages.hideAll()
            }
            SwiftMessages.show(type: MessageType.error, message: tr("noInternetConnection"), duration: MessageDuration.indefinite, id: SwiftMessages.noInternetConnetionMessageId)
        } else {
            update(from: tunnel?.rostamStatus)
            SwiftMessages.hide(id: SwiftMessages.noInternetConnetionMessageId)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reset() {
        rostamImageView.image = UIImage(named: "rostamInactive")
        rostamImageView.isUserInteractionEnabled = false
        busyIndicator.stopAnimating()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
}
