// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import FittedSheets

enum BottomSheetState {
    case collapsed
    case expanded
}

class BottomSheetContentViewController: UIViewController {
    var regionSelected: ((String) -> Void)?
    private var regions: [String]
    private var collapsedView: BottomSheetCollapsedView
    private var expandedView: BottomSheetExpandedView
    var tunnel: TunnelContainer? {
        didSet(value) {
            // Bind to the tunnel's status
            update(from: tunnel?.rostamStatus)
            statusObservationToken = tunnel?.observe(\.status) { [weak self] tunnel, _ in
                self?.update(from: tunnel.rostamStatus)
            }
        }
    }
    private var statusObservationToken: AnyObject?

    init(regions: [String]) {
        self.regions = regions
        self.collapsedView = BottomSheetCollapsedView()
        self.expandedView = BottomSheetExpandedView(regions: regions)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.primaryDark

        view.addSubview(collapsedView)
        collapsedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collapsedView.topAnchor.constraint(equalTo: view.topAnchor),
            collapsedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collapsedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collapsedView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.addSubview(expandedView)
        expandedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            expandedView.topAnchor.constraint(equalTo: view.topAnchor),
            expandedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            expandedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            expandedView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        collapsedView.onExpand = {
            self.expand()
        }

        expandedView.onCollapse = {
            self.collapse()
        }
        expandedView.onRegionSelect = { region in
            self.regionSelected?(region)
        }

        restorationIdentifier = "BottomSheetContentVC"
    }

    override func viewWillAppear(_ animated: Bool) {
        collapsedView.fadeIn()
    }

    override func viewWillLayoutSubviews() {
        if view.frame.size.height > 100.0 {
            expandedView.fadeIn()
            collapsedView.fadeOut()
        } else if view.frame.size.height <= 100.0 {
            collapsedView.fadeIn()
            expandedView.fadeOut()
        }
    }

    func onStateChange(newState: BottomSheetState) {
        if newState == .collapsed {
            collapsedView.fadeIn()
            expandedView.fadeOut()
        } else {
            expandedView.fadeIn()
            collapsedView.fadeOut()
        }
    }

    func expand() {
        if let sheetVC = parent?.parent as? SheetViewController {
            sheetVC.resize(to: .marginFromTop(40))
        }
    }

    func collapse() {
        if let sheetVC = parent?.parent as? SheetViewController {
            sheetVC.resize(to: .fixed(100))
        }
    }

    private func update(from status: TunnelStatus?) {
        guard let status = status else {
            return
        }

        expandedView.allowSelection = status == .inactive
        expandedView.radioTableView.reloadData()
    }
}
