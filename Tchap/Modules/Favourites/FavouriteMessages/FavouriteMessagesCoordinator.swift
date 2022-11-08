// File created from ScreenTemplate
// $ createScreen.sh Favourites/FavouriteMessages FavouriteMessages
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
import UIKit

final class FavouriteMessagesCoordinator: FavouriteMessagesCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var favouriteMessagesViewModel: FavouriteMessagesViewModelType
    private let favouriteMessagesViewController: FavouriteMessagesViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: FavouriteMessagesCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        guard let formatter = EventFormatter(matrixSession: session) else {
            fatalError("[FavouriteMessagesCoordinatorDelegate] init: Cannot build formatter")
        }

        // Use the same event formatter settings as RoomDataSource
        formatter.treatMatrixUserIdAsLink = true
        formatter.treatMatrixRoomIdAsLink = true
        formatter.treatMatrixRoomAliasAsLink = true
//        formatter.treatMatrixGroupIdAsLink = true
        formatter.eventTypesFilterForMessages = MXKAppSettings.standard()?.eventsFilterForMessages

        // But do not display "...(Edited)"
        formatter.showEditionMention = false
        
        let favouriteMessagesViewModel = FavouriteMessagesViewModel(session: self.session, formatter: formatter)
        let favouriteMessagesViewController = FavouriteMessagesViewController.instantiate(with: favouriteMessagesViewModel)
        self.favouriteMessagesViewModel = favouriteMessagesViewModel
        self.favouriteMessagesViewController = favouriteMessagesViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.favouriteMessagesViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.favouriteMessagesViewController
    }
}

// MARK: - FavouriteMessagesViewModelCoordinatorDelegate
extension FavouriteMessagesCoordinator: FavouriteMessagesViewModelCoordinatorDelegate {
    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, didShowRoomWithId roomId: String, onEventId eventId: String) {
        self.delegate?.favouriteMessagesCoordinator(self, didShowRoomWithId: roomId, onEventId: eventId)
    }
    
    func favouriteMessagesViewModelDidCancel(_ viewModel: FavouriteMessagesViewModelType) {
        self.delegate?.favouriteMessagesCoordinatorDidCancel(self)
    }
    
    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, handlePermalinkFragment fragment: String) -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        return delegate.favouriteMessagesCoordinator(self, handlePermalinkFragment: fragment)
    }
}
