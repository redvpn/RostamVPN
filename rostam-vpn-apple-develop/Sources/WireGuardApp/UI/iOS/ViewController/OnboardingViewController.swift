// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class OnboardingViewController: UIPageViewController {
    let pageCount = 2
    var pages = [UIViewController]()

    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.frame = CGRect()
        pageControl.currentPageIndicatorTintColor = UIColor.camel
        pageControl.pageIndicatorTintColor = UIColor.lightGrayishOrange
        pageControl.currentPage = 0
        pageControl.transform = CGAffineTransform(scaleX: 2, y: 2)
        return pageControl
    }()

    let skipButton: UIButton = {
        let skipButton = UIButton()
        skipButton.layer.cornerRadius = 54 / 2
        skipButton.clipsToBounds = true
        skipButton.backgroundColor = UIColor.camel
        skipButton.tintColor = UIColor.white
        skipButton.titleLabel?.font = UIFont(name: "NunitoSans-Bold", size: 18.0)
        skipButton.setTitle(tr("onboardingSkip"), for: .normal)
        return skipButton
    }()

    var onSkipButtonTouched: (() -> Void)?

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let screenSize: CGRect = UIScreen.main.bounds

        self.dataSource = self
        self.delegate = self

        let backgroundView = BackgroundShapeView(frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: view.frame.width, height: view.frame.height * 0.7)))
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)

        for i in 0...pageCount - 1 {
            let page = OnboardingPageViewController(image: getPageImage(index: i), title: getPageTitle(index: i))
            pages.append(page)
        }
        setViewControllers([pages[0]], direction: .reverse, animated: false, completion: nil)
        pageControl.numberOfPages = pageCount

        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: screenSize.height < 600 ? -28.0 : -48.0)
        ])

        view.addSubview(skipButton)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.heightAnchor.constraint(equalToConstant: 54.0),
            skipButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: screenSize.height < 600 ? -20.0 : -40.0),
            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25.0),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25.0)
        ])

        skipButton.addTarget(self, action: #selector(skipButtonTouched), for: .touchUpInside)

        pageControl.addTarget(self, action: #selector(pageChanged), for: .valueChanged)
    }

    @objc func skipButtonTouched(_ sender: UIButton) {
        onSkipButtonTouched?()
    }

    @objc func pageChanged(_ sender: UIPageControl) {
        guard let viewControllers = self.viewControllers, let currentPageIndex = self.pages.firstIndex(of: viewControllers[0]) else { return }

        let pageIndex = sender.currentPage
        if pageIndex > currentPageIndex {
            goToNextPage()
        } else {
            goToPreviousPage()
        }
    }

    private func getPageImage(index: Int) -> String {
        switch index {
        case 0:
            return "illustrationDigitalSafety"
        case 1:
            return "illustrationLock"
        default:
            return ""
        }
    }

    private func getPageTitle(index: Int) -> String {
        switch index {
        case 0:
            return tr("onboardingEncryptOnlineCommunication")
        case 1:
            return tr("onboardingIncreaseDigitalSafety")
        default:
            return ""
        }

    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.pages.firstIndex(of: viewController) {
            if viewControllerIndex > 0 {
                return self.pages[viewControllerIndex - 1]
            }
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.pages.firstIndex(of: viewController) {
            if viewControllerIndex < self.pages.count - 1 {
                return self.pages[viewControllerIndex + 1]
            }
        }
        return nil
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let viewControllers = pageViewController.viewControllers {
            if let viewControllerIndex = self.pages.firstIndex(of: viewControllers[0]) {
                self.pageControl.currentPage = viewControllerIndex
            }
        }
    }
}

extension OnboardingViewController {
    func goToNextPage(animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let nextViewController = dataSource?.pageViewController(self, viewControllerAfter: currentViewController) else { return }
        setViewControllers([nextViewController], direction: .forward, animated: animated, completion: nil)
    }

    func goToPreviousPage(animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let previousViewController = dataSource?.pageViewController(self, viewControllerBefore: currentViewController) else { return }
        setViewControllers([previousViewController], direction: .reverse, animated: animated, completion: nil)
    }
}
