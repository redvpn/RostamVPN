// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import KYDrawerController
import AcknowList

class DrawerViewController: UIViewController {
    private let menuItems = [
        MenuItem(text: tr("aboutRostamTitle"), icon: "iconAbout", viewController: AboutViewController()),
        MenuItem(text: tr("privacyPolicyTitle"), icon: "iconPrivacyPolicy", viewController: PrivacyPolicyViewController())
    ]

    let headerView: UIView = {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.blackDrawer
        return headerView
    }()

    let rostamLogoView: UIImageView = {
        let rostamLogoView = UIImageView()
        rostamLogoView.image = UIImage(named: "rostamLogoDrawer")
        return rostamLogoView
    }()

    let rostamVPNView: UIImageView = {
        let rostamVPNView = UIImageView()
        rostamVPNView.image = UIImage(named: "rostamVPNDrawer")
        return rostamVPNView
    }()

    let menuTableView: UITableView = {
        let menuTableView = UITableView(frame: CGRect.zero, style: .plain)
        menuTableView.separatorStyle = .singleLine
        menuTableView.separatorColor = UIColor.lightGray
        menuTableView.register(NavigationMenuCell.self)
        menuTableView.isScrollEnabled = false
        menuTableView.alwaysBounceVertical = false
        menuTableView.tableFooterView = UIView()
        menuTableView.semanticContentAttribute = .forceRightToLeft
        menuTableView.backgroundColor = .white
        return menuTableView
    }()

    let ossIcon: UIImageView = {
        let ossIcon = UIImageView()
        ossIcon.image = UIImage(named: "iconInfo")!.withRenderingMode(.alwaysTemplate)
        ossIcon.tintColor = UIColor.charcoalGrey
        ossIcon.isUserInteractionEnabled = true
        return ossIcon
    }()

    let socialMediaView: SocialMediaView = {
        let socialMediaView = SocialMediaView()
        return socialMediaView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        menuTableView.dataSource = self
        menuTableView.delegate = self

        view.addSubview(headerView)
        headerView.addSubview(rostamLogoView)
        headerView.addSubview(rostamVPNView)
        view.addSubview(menuTableView)
        view.addSubview(socialMediaView)
        view.addSubview(ossIcon)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        rostamLogoView.translatesAutoresizingMaskIntoConstraints = false
        rostamVPNView.translatesAutoresizingMaskIntoConstraints = false
        menuTableView.translatesAutoresizingMaskIntoConstraints = false
        socialMediaView.translatesAutoresizingMaskIntoConstraints = false
        ossIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 180),

            rostamLogoView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            rostamLogoView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            rostamVPNView.topAnchor.constraint(equalTo: rostamLogoView.bottomAnchor, constant: 8),
            rostamVPNView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            menuTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            menuTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            menuTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            menuTableView.heightAnchor.constraint(equalToConstant: 100),

            socialMediaView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30.0),
            socialMediaView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30.0),
            socialMediaView.topAnchor.constraint(equalTo: menuTableView.bottomAnchor, constant: 250.0),
            socialMediaView.heightAnchor.constraint(equalToConstant: 98.0),

            ossIcon.widthAnchor.constraint(equalToConstant: 24.0),
            ossIcon.heightAnchor.constraint(equalToConstant: 24.0),
            ossIcon.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10.0),
            ossIcon.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -10.0)
        ])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ossIconTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        ossIcon.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func ossIconTapped() {
        if let drawerController = parent as? KYDrawerController {
            guard let mainVC = drawerController.mainViewController as? MainViewController else { return }

            let acknowledgementsViewController = AcknowledgementsViewController()
            if (mainVC.viewControllers.last as? AcknowledgementViewController) != nil {
                mainVC.popViewController(animated: false)
            }
            mainVC.popViewController(animated: false)
            mainVC.viewControllers.last?.navigationItem.title = tr("openSourceLibrariesTitle")
            mainVC.pushViewController(acknowledgementsViewController, animated: false)
            // Deselect menu items...
            if let selectedMenuItem = menuTableView.indexPathForSelectedRow {
                menuTableView.deselectRow(at: selectedMenuItem, animated: false)
            }

            drawerController.setDrawerState(.closed, animated: true)
        }
    }
}

extension DrawerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NavigationMenuCell = tableView.dequeueReusableCell(for: indexPath)

        cell.menuLabel.text = menuItems[indexPath.row].text
        cell.iconImageView.image = UIImage(named: menuItems[indexPath.row].icon)!.withRenderingMode(.alwaysTemplate)

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero

        return cell
    }
}

extension DrawerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let drawerController = parent as? KYDrawerController {
            guard let mainVC = drawerController.mainViewController as? MainViewController else { return }
            if (mainVC.viewControllers.last as? AcknowledgementViewController) != nil {
                mainVC.popViewController(animated: false)
            }
            mainVC.popViewController(animated: false)
            mainVC.viewControllers.last?.navigationItem.title = menuItems[indexPath.row].text
            mainVC.pushViewController(self.menuItems[indexPath.row].viewController, animated: false)

            drawerController.setDrawerState(.closed, animated: true)
        }
    }
}

struct MenuItem {
    var text: String
    var icon: String
    var viewController: UIViewController
}
