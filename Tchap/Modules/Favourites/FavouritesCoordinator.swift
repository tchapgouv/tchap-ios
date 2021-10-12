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

import UIKit

@objcMembers
final class FavouritesCoordinator: FavouritesCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: FavouritesCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
    }    
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createFavouriteMessagesCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createFavouriteMessagesCoordinator() -> FavouriteMessagesCoordinator {
        let coordinator = FavouriteMessagesCoordinator(session: self.session)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - FavouriteMessagesCoordinatorDelegate
extension FavouritesCoordinator: FavouriteMessagesCoordinatorDelegate {
    func favouriteMessagesCoordinator(_ coordinator: FavouriteMessagesCoordinatorType, handlePermalinkFragment fragment: String) -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        return delegate.favouritesCoordinator(self, handlePermalinkFragment: fragment)
    }
    
    func favouriteMessagesCoordinatorDidCancel(_ coordinator: FavouriteMessagesCoordinatorType) {
        self.delegate?.favouritesCoordinatorDidComplete(self)
    }

    func favouriteMessagesCoordinator(_ coordinator: FavouriteMessagesCoordinatorType, didShowRoomWithId roomId: String, onEventId eventId: String) {
        self.delegate?.favouritesCoordinator(self, didShowRoomWithId: roomId, onEventId: eventId)
    }
}
