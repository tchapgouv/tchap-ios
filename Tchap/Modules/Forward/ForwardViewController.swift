// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

protocol ForwardViewControllerDelegate: AnyObject {
    func forwardController(_ viewController: ForwardViewController, searchBar: UISearchBar, textDidChange searchText: String)
    func forwardController(_ viewController: ForwardViewController, searchBarCancelButtonClicked searchBar: UISearchBar)
    func forwardControllerCancelButtonClicked(_ viewController: ForwardViewController)
}

class ForwardViewController: MXKViewController {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var titleContentView: UIView?
    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var searchBar: UISearchBar?
    
    weak var delegate: ForwardViewControllerDelegate?
    
    weak var recentsViewController: UIViewController? {
        willSet {
            guard let recentsViewController = self.recentsViewController else {
                return
            }

            recentsViewController.willMove(toParent: nil)
            recentsViewController.removeFromParent()
            recentsViewController.view.removeFromSuperview()
        }
        didSet {
            if let recentsViewController = self.recentsViewController {
                addRoomsControllerView(recentsViewController)
            }
        }
    }
    
    static func instantiate() -> ForwardViewController {
        return StoryboardScene.ForwardViewController.initialScene.instantiate()
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let recentsViewController = self.recentsViewController {
            addRoomsControllerView(recentsViewController)
        }

        self.navigationController?.isNavigationBarHidden = true
        configureViews()
        self.searchBar?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateTheme()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    // MARK: - Actions
    
    @IBAction private func cancelPressed(sender: UIButton) {
        self.delegate?.forwardControllerCancelButtonClicked(self)
    }
    
    // MARK: - Private
    
    private func configureViews() {
        self.titleLabel?.text = TchapL10n.forwardScreenTitle
    }

    private func addRoomsControllerView(_ viewController: UIViewController) {
        guard let containerView = self.contentView else {
            return
        }
        
        viewController.view.frame = containerView.bounds
        containerView.addSubview(viewController.view)
        addChild(viewController)
        viewController.didMove(toParent: self)
    }
}

// MARK: - UISearchBarDelegate

extension ForwardViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate?.forwardController(self, searchBar: searchBar, textDidChange: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.delegate?.forwardController(self, searchBarCancelButtonClicked: searchBar)
    }
}

// MARK: - Theme

private extension ForwardViewController {
    func updateTheme() {
        self.titleLabel?.textColor = ThemeService.shared().theme.headerTextPrimaryColor
        self.titleContentView?.backgroundColor = ThemeService.shared().theme.headerBackgroundColor
        self.cancelButton?.tintColor = ThemeService.shared().theme.tintColor
        
        self.view.backgroundColor = ThemeService.shared().theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            ThemeService.shared().theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        if let searchBar = self.searchBar {
            ThemeService.shared().theme.applyStyle(onSearchBar: searchBar)
        }
    }
}
