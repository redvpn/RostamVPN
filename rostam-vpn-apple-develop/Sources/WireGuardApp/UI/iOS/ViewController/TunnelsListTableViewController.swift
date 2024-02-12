// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import Connectivity
import KYDrawerController
import SwiftMessages
import FittedSheets

class TunnelsListTableViewController: UIViewController {
    var tunnelsManager: TunnelsManager?
    var digitalSafetyTips: DigitalSafetyTips?
    var sheetVC: SheetViewController?
    let privateKey = KeyStore.shared.privateKey
    let publicKey = KeyStore.shared.publicKey

    let tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.register(TunnelListCell.self)
        tableView.isScrollEnabled = false
        tableView.alwaysBounceVertical = false
        tableView.isHidden = true
        tableView.allowsSelection = false
        return tableView
    }()

    let coverView: UIView = {
        let coverView = UIView(frame: UIScreen.main.bounds)
        coverView.isHidden = true

        // Add gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.white.cgColor, UIColor.lightGrayishOrange.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.frame = coverView.bounds
        coverView.layer.insertSublayer(gradient, at: 0)

        return coverView
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

    let busyIndicator: UIActivityIndicatorView = {
        let busyIndicator: UIActivityIndicatorView
         if #available(iOS 13.0, *) {
            busyIndicator = UIActivityIndicatorView(style: .medium)
         } else {
            busyIndicator = UIActivityIndicatorView(style: .gray)
         }
        busyIndicator.hidesWhenStopped = true
        return busyIndicator
    }()

    override func loadView() {
        view = UIView()

        let screenSize: CGRect = UIScreen.main.bounds

        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(busyIndicator)
        busyIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            busyIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            busyIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        view.addSubview(coverView)
        coverView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            coverView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        coverView.addSubview(rostamImageView)
        rostamImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rostamImageView.centerXAnchor.constraint(equalTo: coverView.centerXAnchor),
            rostamImageView.topAnchor.constraint(equalTo: coverView.topAnchor, constant: 40),
            rostamImageView.widthAnchor.constraint(equalToConstant: CGFloat(screenSize.height < 600 ? 125 : 190)),
            rostamImageView.heightAnchor.constraint(equalToConstant: CGFloat(screenSize.height < 600 ? 200 : 300))
        ])

        coverView.addSubview(stateLabel)
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stateLabel.topAnchor.constraint(equalTo: rostamImageView.bottomAnchor, constant: 20),
            stateLabel.centerXAnchor.constraint(equalTo: coverView.centerXAnchor)
        ])

        coverView.addSubview(infoLabel)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 16),
            infoLabel.centerXAnchor.constraint(equalTo: coverView.centerXAnchor),
            infoLabel.leftAnchor.constraint(equalTo: coverView.leftAnchor, constant: 20),
            infoLabel.rightAnchor.constraint(equalTo: coverView.rightAnchor, constant: -20)
        ])

        rostamImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        rostamImageView.addGestureRecognizer(tapGestureRecognizer)

        #if !targetEnvironment(simulator)
        busyIndicator.startAnimating()
        #endif
    }

    @objc func imageTapped() {
        guard let tunnelsManager = self.tunnelsManager else { return }

        #if !targetEnvironment(simulator)
        let tunnelNames = tunnelsManager.mapTunnels { $0.name }

        if tunnelNames.contains(AppDelegate.tunnelName) == false {
            ConfigBuilder.build(privateKey: self.privateKey!, publicKey: self.publicKey!, region: nil) { wgQuickConfig in
                if let wgQuickConfig = wgQuickConfig, let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: wgQuickConfig, called: AppDelegate.tunnelName) {

                    tunnelsManager.add(tunnelConfiguration: tunnelConfiguration) { result in
                        switch result {
                        case .failure(let error):
                            debugPrint(error.alertText)
                        case .success(let tunnelContainer):
                            debugPrint("Tunnel \(tunnelContainer.name) created.")
                        }
                    }
                } else {
                    let urlPath = Bundle.main.path(forResource: "tunnel", ofType: "conf")
                    let url = URL(fileURLWithPath: urlPath!)
                    TunnelImporter.importTunnel(url: url, into: tunnelsManager) {
                        _ = FileManager.deleteFile(at: url)
                    }
                }
            }
        }
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()

        digitalSafetyTips = DigitalSafetyTips()

        // Get regions and set up bottom sheet...
        var regions: [String]?
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        DispatchQueue.main.async {
            RegionManager.shared.loadRegions { data in
                regions = data
                dispatchGroup.leave()
            }
        }

        // TODO: Uncomment this code to enable the regions bottom sheet in the future
//        dispatchGroup.notify(queue: .main) {
//            self.setupBottomSheet(regions: regions!)
//        }

        restorationIdentifier = "TunnelsListVC"
    }

    override func viewWillAppear(_: Bool) {
        if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRowIndexPath, animated: false)
        }

        // Deselect menu items...
        if let drawerController = parent?.parent as? KYDrawerController {
            guard let drawerVC = drawerController.drawerViewController as? DrawerViewController else { return }

            let menuTableView = drawerVC.menuTableView
            if let selectedMenuItem = menuTableView.indexPathForSelectedRow {
                menuTableView.deselectRow(at: selectedMenuItem, animated: false)
            }
        }

        // TODO: Uncomment this code to enable the regions bottom sheet in the future
//        self.displayBottomSheet()
    }

    override func viewWillDisappear(_: Bool) {
        self.sheetVC?.animateOut()
    }

//    func setupBottomSheet(regions: [String]) {
//        let bottomSheetContentVC = BottomSheetContentViewController(regions: regions)
//        if let tunnelsManager = self.tunnelsManager, let tunnel: TunnelContainer = tunnelsManager.tunnel(named: AppDelegate.tunnelName) {
//            bottomSheetContentVC.tunnel = tunnel
//        }
//        let options = SheetOptions(useInlineMode: true)
//        self.sheetVC = SheetViewController(controller: bottomSheetContentVC, sizes: [.fixed(100), .marginFromTop(40)], options: options)
//
//        let sheetVC = self.sheetVC!
//
//        sheetVC.cornerRadius = 35
//        sheetVC.gripColor = .clear
//        sheetVC.overlayColor = .clear
//        sheetVC.allowGestureThroughOverlay = true
//        sheetVC.dismissOnPull = false
//        sheetVC.dismissOnOverlayTap = false
//
//        sheetVC.sizeChanged = { sheet, sheetSize, size in
//            let newState: BottomSheetState = sheetSize == .fixed(100) ? .collapsed : .expanded
//            bottomSheetContentVC.onStateChange(newState: newState)
//        }
//
//        bottomSheetContentVC.regionSelected = { region in
//            self.handleRegionChange(region: region)
//        }
//
//        self.displayBottomSheet()
//    }
//
//    func displayBottomSheet() {
//        guard let sheetVC = self.sheetVC else { return }
//
//        sheetVC.willMove(toParent: self)
//        self.addChild(sheetVC)
//        view.addSubview(sheetVC.view)
//        sheetVC.didMove(toParent: self)
//
//        sheetVC.view.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            sheetVC.view.topAnchor.constraint(equalTo: view.topAnchor),
//            sheetVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            sheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            sheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//        ])
//
//        sheetVC.animateIn()
//    }
//
//    func handleRegionChange(region: String) {
//        debugPrint("Region selected: \(region)")
//        RegionManager.shared.setSelectedRegion(region: region)
//        if let tunnelsManager = self.tunnelsManager, let tunnel: TunnelContainer = tunnelsManager.tunnel(named: AppDelegate.tunnelName) {
//            let endpointManager = EndpointManager(tunnel: tunnel, region: region)
//            if let endpoint: Endpoint = endpointManager.getNextEndpoint() {
//                if let mainVC = self.parent as? MainViewController {
//                    mainVC.changeTunnelEndpoint(tunnel: tunnel, endpoint: endpoint) { result in
//                        debugPrint("Result: \(result)")
//                    }
//                }
//            } else {
//                self.getNewEndpoints(tunnelsManager: tunnelsManager, tunnel: tunnel, region: region, checked: false)
//            }
//        }
//    }

    func setupNavigationBar() {
        let navigationBar = navigationController!.navigationBar
        navigationBar.setBackgroundImage(UIImage(),
                                         for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.barTintColor = .white
        navigationBar.isTranslucent = false
        navigationBar.tintColor = UIColor.primaryDark

        if #available(iOS 13.0, *) {
            let standardAppearance = navigationBar.standardAppearance.copy()

            let titleTextAttributes = [
                NSAttributedString.Key.font: UIFont(name: "NunitoSans-Bold", size: 20.0)!,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]

            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = .white
            standardAppearance.shadowColor = nil
            standardAppearance.buttonAppearance.normal.titleTextAttributes = titleTextAttributes

            navigationBar.standardAppearance = standardAppearance
            navigationBar.scrollEdgeAppearance = standardAppearance
        }

        navigationItem.titleView = UIImageView(image: UIImage(named: "rostamVPN"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMenu"), style: .plain, target: self, action: #selector(menuButtonTapped))
    }

    func showDigitalSafetyTip() {
        guard let digitalSafetyTips = self.digitalSafetyTips else { return }

        if !digitalSafetyTips.isEmpty(),
            let tip: DigitalSafetyTip = digitalSafetyTips.getNextTip() {
            SwiftMessages.showDigitalSafetyMessage(title: tip.title, shortDescription: tip.shortDescription, link: tip.url)
        }
    }

    @objc func menuButtonTapped(_ sender: UIButton) {
        if let drawerController = parent?.parent as? KYDrawerController {
            drawerController.setDrawerState(.opened, animated: true)
        }
    }

    func setTunnelsManager(tunnelsManager: TunnelsManager) {
        self.tunnelsManager = tunnelsManager
        tunnelsManager.tunnelsListDelegate = self

        #if !targetEnvironment(simulator)
        // Update the tunnel if its private key is not the same as the stored private key...
        if let tunnel: TunnelContainer = tunnelsManager.tunnel(named: AppDelegate.tunnelName),
           let privateKey = tunnel.tunnelConfiguration?.interface.privateKey, privateKey.rawValue != self.privateKey?.rawValue {
            let selectedRegion = RegionManager.shared.getSelectedRegion()
            ConfigBuilder.build(privateKey: self.privateKey!, publicKey: self.publicKey!, region: selectedRegion) { wgQuickConfig in
                if let wgQuickConfig = wgQuickConfig, let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: wgQuickConfig, called: AppDelegate.tunnelName) {

                    tunnelsManager.modify(tunnel: tunnel, tunnelConfiguration: tunnelConfiguration) { modifyError in
                        let alertText = modifyError?.alertText
                        if let alertText = alertText {
                            debugPrint(alertText)
                        }

                        self.busyIndicator.stopAnimating()
                        self.tableView.isHidden = false
                    }
                } else {
                    self.busyIndicator.stopAnimating()
                    self.tableView.isHidden = false
                }
            }
        } else {
            busyIndicator.stopAnimating()
            self.tableView.isHidden = false
        }
        #else
        busyIndicator.stopAnimating()
        self.tableView.isHidden = false
        #endif
        tableView.reloadData()
        coverView.isHidden = tunnelsManager.numberOfTunnels() > 0
    }
}

extension TunnelsListTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tunnelsManager?.numberOfTunnels() ?? 0)
    }

    func getNewEndpoints(tunnelsManager: TunnelsManager, tunnel: TunnelContainer, region: String, checked: Bool) {
        tunnel.isGettingNewEndpoints = true
        ConfigBuilder.build(privateKey: self.privateKey!, publicKey: self.publicKey!, region: region) { wgQuickConfig in
            if let wgQuickConfig = wgQuickConfig, let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: wgQuickConfig, called: AppDelegate.tunnelName) {

                tunnelsManager.modify(tunnel: tunnel, tunnelConfiguration: tunnelConfiguration) { modifyError in
                    SwiftMessages.hideAll()
                    let alertText = modifyError?.alertText
                    if let alertText = alertText {
                        debugPrint(alertText)
                        SwiftMessages.showConfigRequestMessage()
                    } else if checked {
                        self.showDigitalSafetyTip()
                        tunnelsManager.startActivation(of: tunnel)
                    }
                    tunnel.isGettingNewEndpoints = false
                }
            } else {
                SwiftMessages.hideAll()
                SwiftMessages.showConfigRequestMessage()
                tunnel.isGettingNewEndpoints = false
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TunnelListCell = tableView.dequeueReusableCell(for: indexPath)
        if let tunnelsManager = tunnelsManager {
            let tunnel = tunnelsManager.tunnel(at: indexPath.row)
            cell.tunnel = tunnel
            cell.onImageTapped = { () in
                guard let tunnelsManager = self.tunnelsManager else { return }
                if tunnel.rostamStatus == .inactive {
                    // If there are no stored endpoints get new ones, otherwise turn VPN on...
                    let selectedRegion = RegionManager.shared.getSelectedRegion()
                    let endpointManager = EndpointManager(tunnel: tunnel, region: selectedRegion)
                    if endpointManager.getNextEndpoint() == nil {
                        self.getNewEndpoints(tunnelsManager: tunnelsManager, tunnel: tunnel, region: selectedRegion, checked: true)
                    } else {
                        SwiftMessages.hideAll()
                        self.showDigitalSafetyTip()
                        tunnelsManager.startActivation(of: tunnel)
                    }
                } else if tunnel.rostamStatus == .active {
                    tunnelsManager.startDeactivation(of: tunnel)
                }
            }
        }

        // Add gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.white.cgColor, UIColor.lightGrayishOrange.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: cell.frame.size.width, height: cell.frame.size.height)
        cell.layer.insertSublayer(gradient, at: 0)

        return cell
    }
}

extension TunnelsListTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tunnelListCell = cell as? TunnelListCell else { return }
        ConnectivityManager.shared.addListener(listener: tunnelListCell)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let networkListenerCell = cell as? NetworkStatusListener else { return }
        ConnectivityManager.shared.removeListener(listener: networkListenerCell)
    }
}

extension TunnelsListTableViewController: TunnelsManagerListDelegate {
    func tunnelAdded(at index: Int) {
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        coverView.isHidden = (tunnelsManager?.numberOfTunnels() ?? 0 > 0)
    }

    func tunnelModified(at index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    func tunnelMoved(from oldIndex: Int, to newIndex: Int) {
        tableView.moveRow(at: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: newIndex, section: 0))
    }

    func tunnelRemoved(at index: Int, tunnel: TunnelContainer) {
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        coverView.isHidden = (tunnelsManager?.numberOfTunnels() ?? 0 > 0)
    }
}
