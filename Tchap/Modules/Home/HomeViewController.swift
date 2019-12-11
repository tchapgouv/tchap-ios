/*
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

protocol HomeViewControllerDelegate: class {
    func homeViewControllerDidTapStartChatButton(_ homeViewController: HomeViewController)
    func homeViewControllerDidTapCreateRoomButton(_ homeViewController: HomeViewController)
    func homeViewControllerDidTapPublicRoomsAccessButton(_ homeViewController: HomeViewController)
}

final class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var segmentedViewControllerContainerView: UIView!
    @IBOutlet private weak var plusButton: UIButton!
    
    // MARK: Private
    
    private var globalSearchBar: GlobalSearchBar!
    private var currentStyle: Style!
    private var segmentedViewController: SegmentedViewController?
    private var segmentViewControllers: [UIViewController] = []
    private var segmentViewControllersTitles: [String] = []
    private var isExternalUseMode: Bool = false
    
    private weak var currentAlertController: UIAlertController?
    
    // MARK: Public
    
    weak var delegate: HomeViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(with viewControllers: [UIViewController], viewControllersTitles: [String], globalSearchBar: GlobalSearchBar, style: Style = Variant1Style.shared) -> HomeViewController {
        let viewController = StoryboardScene.HomeViewController.initialScene.instantiate()
        viewController.segmentViewControllers = viewControllers
        viewController.segmentViewControllersTitles = viewControllersTitles
        viewController.globalSearchBar = globalSearchBar
        viewController.currentStyle = style
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupGlobalSearchBar()
        self.setupSegmentedViewController()
        self.setupPlusButton()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.globalSearchBar.resetSearchText()
    }
        
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.currentStyle.statusBarStyle
    }
    
    func setExternalUseMode(_ isExternal: Bool) {
        isExternalUseMode = isExternal
        self.setupPlusButton()
    }
    
    func setSelectedTabIndex(_ index: UInt) {
        guard let segmentedViewController = self.segmentedViewController else {
            return
        }
        segmentedViewController.selectedIndex = index
    }
    
    // MARK: - Private
    
    private func setupGlobalSearchBar() {
        if let navigationBar = self.navigationController?.navigationBar {
            self.globalSearchBar.frame = navigationBar.frame
        }
        self.navigationItem.titleView = globalSearchBar
    }
    
    private func setupSegmentedViewController() {
        guard self.segmentedViewControllerContainerView.subviews.isEmpty, let segmentedViewController = SegmentedViewController.instantiate() else {
            return
        }
        segmentedViewController.initWithTitles(self.segmentViewControllersTitles, viewControllers: self.segmentViewControllers, defaultSelected: 0)
        self.tc_addChildViewController(viewController: segmentedViewController, onView: self.segmentedViewControllerContainerView)
        self.segmentedViewController = segmentedViewController
    }
    
    private func setupPlusButton() {
        // Hide the plus button for external user (the corresponding actions are not allowed for them)
        self.plusButton?.isHidden = isExternalUseMode
    }
    
    // MARK: - Action
    
    @IBAction private func plusButtonAction(_ sender: Any) {
        self.currentAlertController?.dismiss(animated: false)
        
        let currentAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        currentAlert.addAction(UIAlertAction(title: TchapL10n.conversationsStartChatAction, style: .default, handler: { action in
            self.delegate?.homeViewControllerDidTapStartChatButton(self)
        }))
        
        currentAlert.addAction(UIAlertAction(title: TchapL10n.conversationsCreateRoomAction, style: .default, handler: { action in
            self.delegate?.homeViewControllerDidTapCreateRoomButton(self)
        }))
        
        currentAlert.addAction(UIAlertAction(title: TchapL10n.conversationsAccessToPublicRoomsAction, style: .default, handler: { action in
            self.delegate?.homeViewControllerDidTapPublicRoomsAccessButton(self)
        }))
        
        currentAlert.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "cancel"), style: .cancel, handler: { action in
            
        }))
        
        currentAlert.popoverPresentationController?.sourceView = self.plusButton
        currentAlert.popoverPresentationController?.sourceRect = self.plusButton.bounds
        
        self.present(currentAlert, animated: true)
        
        self.currentAlertController = currentAlert
    }
}

// MARK: - Stylable
extension HomeViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
    }
}
