// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import os.log
import KYDrawerController
import Amplitude

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var mainVC: MainViewController?
    var isLaunchedForSpecificAction = false
    static let tunnelName = "Rostam"
    let onboardingKey = "onboardingCompleted"
//    let onboardingKey = "onboardingCompletedV1.3.0"

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Force RTL
        UIView.appearance().semanticContentAttribute = .forceRightToLeft

        // Force light mode
        UIView.appearance().overrideUserInterfaceStyle = .light

        Logger.configureGlobal(tagged: "APP", withFilePath: FileManager.logFileURL?.path)

        if let launchOptions = launchOptions {
            if launchOptions[.url] != nil || launchOptions[.shortcutItem] != nil {
                isLaunchedForSpecificAction = true
            }
        }

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        self.window = window

        let mainVC = MainViewController()
        let drawerVC = DrawerViewController()
        let drawerController = KYDrawerController(drawerDirection: .right, drawerWidth: 292)
        drawerController.mainViewController = mainVC
        drawerController.drawerViewController = drawerVC

        if UserDefaults.standard.bool(forKey: onboardingKey) {
            window.rootViewController = drawerController
        } else {
            let onboardingVC = OnboardingViewController()
            onboardingVC.onSkipButtonTouched = {
                let termsAndConditionsVC = TermsAndConditionsViewController()
                termsAndConditionsVC.onAcceptButtonTouched = {
                    window.rootViewController = drawerController
                    UserDefaults.standard.set(true, forKey: self.onboardingKey)
                }
                window.rootViewController = termsAndConditionsVC
            }
            window.rootViewController = onboardingVC
        }
        window.makeKeyAndVisible()

        self.mainVC = mainVC

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize Amplitude and disable tracking of some properties...
        let options = AMPTrackingOptions().disableDMA()?.disableIPAddress()?.disableLatLng()?.disableRegion()?.disableIDFA()?.disableIDFV()

//        Amplitude.instance()?.useAdvertisingIdForDeviceId()
//        Amplitude.instance()?.setTrackingOptions(options)
//        Amplitude.instance()?.initializeApiKey("2c1817902dec273dfc4ad8a6af5c5c5e")
//
//        // Create a Sentry client and start crash handler
//        do {
//            Client.shared = try Client(dsn: "https://00a6f4c5d52d4df9abc2b008e81a744a@sentry.io/1727738")
//            try Client.shared?.startCrashHandler()
//        } catch let error {
//            debugPrint("\(error)")
//        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // If the tunnels manager is ready use it. If not, wait for it to be created...
        guard let tunnelsManager = mainVC?.tunnelsManager else {
            mainVC?.onTunnelsManagerReady = { tunnelsManager in
                TunnelImporter.updateFromFile(url: url, into: tunnelsManager) {
                    _ = FileManager.deleteFile(at: url)
                }
            }

            return true
        }

        TunnelImporter.updateFromFile(url: url, into: tunnelsManager) {
            _ = FileManager.deleteFile(at: url)
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        mainVC?.refreshTunnelConnectionStatuses()

        // Starts monitoring network connectivity status changes
        ConnectivityManager.shared.startMonitoring()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        guard let allTunnelNames = mainVC?.allTunnelNames() else { return }
        application.shortcutItems = QuickActionItem.createItems(allTunnelNames: allTunnelNames)

        // Stops monitoring network connectivity status changes
        ConnectivityManager.shared.stopMonitoring()
    }

    func setMainVC() {
        guard let window = self.window else { return }

        let mainVC = MainViewController()
        let drawerVC = DrawerViewController()
        let drawerController = KYDrawerController(drawerDirection: .right, drawerWidth: 292)
        drawerController.mainViewController = mainVC
        drawerController.drawerViewController = drawerVC

        window.rootViewController = drawerController
        window.makeKeyAndVisible()

        self.mainVC = mainVC
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return !self.isLaunchedForSpecificAction
    }
}
