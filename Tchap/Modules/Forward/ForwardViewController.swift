// 
// Copyright 2020 New Vector Ltd
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

class ForwardViewController: MXKViewController {
    @IBOutlet var containerView: UIView?
    
    private var currentStyle: Style!
    var searchBar: UISearchBar!
    
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
        viewController.searchBar = UISearchBar()
        viewController.navigationItem.prompt = TchapL10n.roomEventActionForward
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let roomsViewController = self.roomsViewController {
            addRoomsControllerView(roomsViewController)
        }

        setupGlobalSearchBar()
//        update(style: self.currentStyle)
    }
    
    // MARK: - Private
    
    private func setupGlobalSearchBar() {
//        if let navigationBar = self.navigationController?.navigationBar {
//            self.globalSearchBar.frame = navigationBar.frame
//        }
//        self.navigationItem.titleView = globalSearchBar
        self.navigationItem.titleView = searchBar
    }
    
    private func addRoomsControllerView(_ roomsViewController: UIViewController) {
        guard let containerView = self.containerView else {
            return
        }
        
        roomsViewController.view.frame = containerView.bounds
        containerView.addSubview(roomsViewController.view)
        addChild(roomsViewController)
        roomsViewController.didMove(toParent: self)
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
