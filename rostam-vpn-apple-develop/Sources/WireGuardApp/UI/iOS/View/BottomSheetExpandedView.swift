// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class BottomSheetExpandedView: UIView {
    var onCollapse: (() -> Void)?
    var onRegionSelect: ((String) -> Void)?
    private var regions: [String]
    var allowSelection = true

    let title: UILabel = {
        let title = UILabel()
        title.font = UIFont(name: "NunitoSans-Bold", size: 24.0)
        title.numberOfLines = 0
        title.textColor = .white
        title.text = tr("servers")
        return title
    }()

    let chevronDown: UIImageView = {
        let chevronDown = UIImageView()
        chevronDown.image = UIImage(named: "iconChevronDown")
        chevronDown.tintColor = .white
        return chevronDown
    }()

    let turnVpnOffLabel: UILabel = {
        let freeServersLabel = UILabel()
        freeServersLabel.font = UIFont(name: "NunitoSans-Regular", size: 18.0)
        freeServersLabel.numberOfLines = 0
        freeServersLabel.textColor = .white
        freeServersLabel.text = tr("turnVpnOffToChooseServerLocation")
        return freeServersLabel
    }()

    let radioTableView: UITableView = {
        let radioTableView = UITableView(frame: CGRect.zero, style: .plain)
        radioTableView.separatorStyle = .singleLine
        radioTableView.separatorColor = UIColor.brownGrey
        radioTableView.backgroundColor = .clear
        radioTableView.register(RegionRadioCell.self)
        radioTableView.isScrollEnabled = true
        radioTableView.alwaysBounceVertical = false
        radioTableView.tableFooterView = UIView()
        radioTableView.semanticContentAttribute = .forceRightToLeft
        return radioTableView
    }()

    init(regions: [String]) {
        self.regions = regions

        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        radioTableView.delegate = self
        radioTableView.dataSource = self

        self.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25.0),
            title.topAnchor.constraint(equalTo: self.topAnchor, constant: 39.0)
        ])

        self.addSubview(chevronDown)
        chevronDown.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chevronDown.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -28.0),
            chevronDown.topAnchor.constraint(equalTo: self.topAnchor, constant: 39.0),
            chevronDown.widthAnchor.constraint(equalToConstant: 32.0),
            chevronDown.heightAnchor.constraint(equalToConstant: 32.0)
        ])

        self.addSubview(turnVpnOffLabel)
        turnVpnOffLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            turnVpnOffLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25.0),
            turnVpnOffLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 27.0)
        ])

        self.addSubview(radioTableView)
        radioTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radioTableView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25.0),
            radioTableView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -32.0),
            radioTableView.topAnchor.constraint(equalTo: turnVpnOffLabel.bottomAnchor, constant: 17.0),
            radioTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        chevronDown.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onChevronDownTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        chevronDown.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func onChevronDownTapped() {
        onCollapse?()
    }
}

extension BottomSheetExpandedView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RegionRadioCell = tableView.dequeueReusableCell(for: indexPath)
        let region = regions[indexPath.row]

        cell.regionLabel.text = tr(region)
        cell.regionLabel.textColor = allowSelection ? .white : UIColor.brownGrey
        cell.flagImageView.image = UIImage(named: "flag_\(region)")
        cell.radioImageView.image = UIImage(named: "radioUnchecked")

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.selectionStyle = .none

        return cell
    }
}

extension BottomSheetExpandedView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let region = regions[indexPath.row]
        let selectedRegion = RegionManager.shared.getSelectedRegion()

        if region == selectedRegion {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let region = regions[indexPath.row]
        let selectedRegion = RegionManager.shared.getSelectedRegion()

        if !allowSelection && region != selectedRegion {
            return nil
        }

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRegion = RegionManager.shared.getSelectedRegion()
        let newRegion = regions[indexPath.row]
        if newRegion != selectedRegion {
            onRegionSelect?(newRegion)
        }
        onCollapse?()
    }
}
