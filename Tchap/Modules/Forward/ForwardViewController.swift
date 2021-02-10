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

protocol ForwardViewControllerDelegate: class {
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

    private var currentStyle: Style!
    
    weak var roomsViewController: UIViewController? {
        willSet {
            guard let roomsViewController = self.roomsViewController else {
                return
            }
            
            roomsViewController.willMove(toParent: nil)
            roomsViewController.removeFromParent()
            roomsViewController.view.removeFromSuperview()
        }
        didSet {
            if let roomsViewController = self.roomsViewController {
                addRoomsControllerView(roomsViewController)
            }
        }
    }
    
    static func instantiate(with style: Style) -> ForwardViewController {
        let viewController = StoryboardScene.ForwardViewController.initialScene.instantiate()
        viewController.currentStyle = style
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let roomsViewController = self.roomsViewController {
            addRoomsControllerView(roomsViewController)
        }

        self.navigationController?.isNavigationBarHidden = true
        configureViews()
        self.searchBar?.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction private func cancelPressed(sender: UIButton) {
        self.delegate?.forwardControllerCancelButtonClicked(self)
    }
    
    // MARK: - Private
    
    private func configureViews() {
        self.titleLabel?.text = TchapL10n.roomEventActionForward
        self.titleLabel?.textColor = kVariant1BarTitleColor
        self.titleContentView?.backgroundColor = kVariant1BarBgColor
        self.cancelButton?.tintColor = kVariant1BarActionColor
        self.searchBar?.backgroundColor = kVariant1BarBgColor
        self.searchBar?.barTintColor = kVariant1BarBgColor
    }

    private func addRoomsControllerView(_ roomsViewController: UIViewController) {
        guard let containerView = self.contentView else {
            return
        }
        
        roomsViewController.view.frame = containerView.bounds
        containerView.addSubview(roomsViewController.view)
        addChild(roomsViewController)
        roomsViewController.didMove(toParent: self)
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

// MARK: - Stylable

extension ForwardViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
    }
}
