// File created from FlowTemplate
// $ createRootCoordinator.sh Favourites Favourites FavouriteMessages
/*
 Copyright 2020 New Vector Ltd
 
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

import Foundation

@objc protocol FavouritesCoordinatorBridgePresenterDelegate {
    func favouritesCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: FavouritesCoordinatorBridgePresenter)
}

/// FavouritesCoordinatorBridgePresenter enables to start FavouritesCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers). Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class FavouritesCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var coordinator: FavouritesCoordinator?
    
    // MARK: Public
    
    weak var delegate: FavouritesCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let favouritesCoordinator = FavouritesCoordinator(session: self.session)
        favouritesCoordinator.delegate = self
        viewController.present(favouritesCoordinator.toPresentable(), animated: animated, completion: nil)
        favouritesCoordinator.start()
        
        self.coordinator = favouritesCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - FavouritesCoordinatorDelegate
extension FavouritesCoordinatorBridgePresenter: FavouritesCoordinatorDelegate {
    func favouritesCoordinatorDidComplete(_ coordinator: FavouritesCoordinatorType) {
        self.delegate?.favouritesCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}
