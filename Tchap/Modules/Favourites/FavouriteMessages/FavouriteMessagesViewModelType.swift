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

protocol FavouriteMessagesViewModelViewDelegate: AnyObject {
    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, didUpdateViewState viewState: FavouriteMessagesViewState)
}

protocol FavouriteMessagesViewModelCoordinatorDelegate: AnyObject {
    func favouriteMessagesViewModelDidCancel(_ viewModel: FavouriteMessagesViewModelType)
    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, didShowRoomWithId roomId: String, onEventId eventId: String)
    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, handlePermalinkFragment fragment: String) -> Bool
}

/// Protocol describing the view model used by `FavouriteMessagesViewController`
protocol FavouriteMessagesViewModelType {        
        
    var viewDelegate: FavouriteMessagesViewModelViewDelegate? { get set }
    var coordinatorDelegate: FavouriteMessagesViewModelCoordinatorDelegate? { get set }
    var titleViewModel: RoomTitleViewModel { get }
    
    func process(viewAction: FavouriteMessagesViewAction)
}
